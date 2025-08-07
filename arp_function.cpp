#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _DEBUG
#undef _DEBUG
#include <Python.h>
#define _DEBUG
#else
#include <Python.h>
#endif
#include < stdint.h>
#include <svdpi.h>
#include <iostream>
using namespace std;
static PyObject *arp_module = NULL;
static PyObject *create_arp_frame_func = NULL;
static PyObject *create_eth_frame_func = NULL;
static PyObject *create_ip_header_func = NULL;
static PyObject *create_udp_header_func = NULL;

int init_python_wrapper()
{
	Py_Initialize();
	// Add current directory to sys.path
	PyRun_SimpleString("import sys\n"
					   "sys.path.insert(0, '')\n");
	PyObject *sys_path = PySys_GetObject("path");
	if (!sys_path)
	{
		printf("Error: Could not get sys.path\n");
		PyErr_Print();
		return -1;
	}

	// Debug: Print current Python paths
	// printf("Current Python sys.path:\n");
	// for (int i = 0; i < PyList_Size(sys_path); i++) {
	//     PyObject* item = PyList_GetItem(sys_path, i);
	//     const char* path = PyUnicode_AsUTF8(item);
	//     if (path) {
	//         printf("  [%d] %s\n", i, path);
	//     }
	// }

	// Add custom script directory
	const char *paths[] = {
		"src/python",
		"C:/Users/wasee/AppData/Local/Programs/Python/Python313/Lib/site-packages"};

	for (int i = 0; i < sizeof(paths) / sizeof(paths[0]); i++)
	{
		PyObject *path = PyUnicode_FromString(paths[i]);
		if (!path)
		{
			printf("Error creating path object for %s\n", paths[i]);
			continue;
		}

		if (PyList_Append(sys_path, path) == -1)
		{
			printf("Error adding path: %s\n", paths[i]);
			PyErr_Print();
		}
		// else {
		//     printf("Added to sys.path: %s\n", paths[i]);
		// }
		Py_DECREF(path);
	}

	// Import our Python module
	printf("Importing arp_function module...\n");
	arp_module = PyImport_ImportModule("arp_function");
	if (!arp_module)
	{
		printf("Error importing module:\n");
		PyErr_Print();

		// Check if module exists
		PyObject *module_name = PyUnicode_FromString("arp_function");
		if (PyImport_Import(module_name) == NULL)
		{
			printf("Module arp_function cannot be imported. Check these locations:\n");
			for (int i = 0; i < PyList_Size(sys_path); i++)
			{
				PyObject *item = PyList_GetItem(sys_path, i);
				const char *path = PyUnicode_AsUTF8(item);
				if (path)
				{
					printf("  - %s/arp_function.py\n", path);
				}
			}
		}
		Py_XDECREF(module_name);
		return -1;
	}

	// Get function references
	create_arp_frame_func = PyObject_GetAttrString(arp_module, "create_arp_frame");
	create_eth_frame_func = PyObject_GetAttrString(arp_module, "create_eth_frame");
	create_ip_header_func = PyObject_GetAttrString(arp_module, "create_ip_header");
	create_udp_header_func = PyObject_GetAttrString(arp_module, "create_udp_header");

	if (!create_arp_frame_func || !create_eth_frame_func ||
		!create_ip_header_func || !create_udp_header_func)
	{
		PyErr_Print();
		fprintf(stderr, "Failed to retrieve one or more Python functions\n");
		return 1;
	}

	printf("Python wrapper initialized successfully\n");
	return 0;
}
// Clean up Python resources before exiting
void cleanup_python_wrapper()
{
	if (create_arp_frame_func)
		Py_DECREF(create_arp_frame_func);
	if (create_eth_frame_func)
		Py_DECREF(create_eth_frame_func);
	if (create_ip_header_func)
		Py_DECREF(create_ip_header_func);
	if (create_udp_header_func)
		Py_DECREF(create_udp_header_func);

	Py_Finalize(); // Shut down the Python interpreter
}

int convert_python_list_to_c_array(PyObject *py_list, unsigned char *c_array, int max_size)
{
    if (!PyList_Check(py_list)) {
        printf("Error: Python object is not a list\n");
        return -1;
    }

    Py_ssize_t list_size = PyList_Size(py_list);
    if (list_size > max_size) {
        printf("Error: List too large for C array\n");
        return -1;
    }

    for (Py_ssize_t i = 0; i < list_size; i++) {
        PyObject *item = PyList_GetItem(py_list, i);
        if (!PyLong_Check(item)) {
            printf("Error: List item %zd is not an integer\n", i);
            return -1;
        }

        long val = PyLong_AsLong(item);
        if (val < 0 || val > 255) {
            printf("Error: Value at index %zd (%ld) is out of byte range\n", i, val);
            return -1;
        }

        c_array[i] = (unsigned char)val;
    }

    return (int)list_size;
}

int create_arp_frame_c(const char *hwsrc, const char *psrc,
					   const char *hwdst, const char *pdst,
					   unsigned char *arp_bytes, int *arp_len)
{
	// Convert arguments to Python strings
	PyObject *py_hwsrc = PyUnicode_FromString(hwsrc);
	PyObject *py_psrc = PyUnicode_FromString(psrc);
	PyObject *py_hwdst = PyUnicode_FromString(hwdst);
	PyObject *py_pdst = PyUnicode_FromString(pdst);

	// Pack arguments into a Python tuple
	PyObject *args = PyTuple_Pack(4, py_hwsrc, py_psrc, py_hwdst, py_pdst);

	// Call the Python function (must be already imported and initialized)
	PyObject *result = PyObject_CallObject(create_arp_frame_func, args);

	if (!result || !PyList_Check(result))
	{
		printf("Error: Python function did not return a list\n");
		Py_XDECREF(result);
		Py_DECREF(args);
		Py_DECREF(py_hwsrc);
		Py_DECREF(py_psrc);
		Py_DECREF(py_hwdst);
		Py_DECREF(py_pdst);
		return -1;
	}

	// Convert result to C array
	int size = convert_python_list_to_c_array(result, arp_bytes, 28); // max ARP size
	if (size < 0)
	{
		printf("Error: Failed to convert Python list to C array\n");
		Py_DECREF(result);
		Py_DECREF(args);
		Py_DECREF(py_hwsrc);
		Py_DECREF(py_psrc);
		Py_DECREF(py_hwdst);
		Py_DECREF(py_pdst);
		return -1;
	}

	*arp_len = size;

	// Cleanup
	Py_DECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_hwsrc);
	Py_DECREF(py_psrc);
	Py_DECREF(py_hwdst);
	Py_DECREF(py_pdst);

	return 0;
}
int create_eth_frame_c(const char *src_mac, const char *dst_mac,
					   unsigned char *eth_bytes, int *eth_len)
{
	PyObject *py_src = PyUnicode_FromString(src_mac);
	PyObject *py_dst = PyUnicode_FromString(dst_mac);
	PyObject *args = PyTuple_Pack(2, py_src, py_dst);

	PyObject *result = PyObject_CallObject(create_eth_frame_func, args);

	if (!result || !PyList_Check(result))
	{
		printf("Error: Python function did not return a list\n");
		goto error;
	}

	int size = convert_python_list_to_c_array(result, eth_bytes, 14); // Ethernet header size
	if (size < 0)
	{
		printf("Error converting Python list to C array\n");
		goto error;
	}

	*eth_len = size;

	Py_DECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_src);
	Py_DECREF(py_dst);
	return 0;

error:
	Py_XDECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_src);
	Py_DECREF(py_dst);
	return -1;
}
int create_ip_header_c(const char *src_ip, const char *dst_ip,
					   unsigned char *ip_bytes, int *ip_len)
{
	PyObject *py_src = PyUnicode_FromString(src_ip);
	PyObject *py_dst = PyUnicode_FromString(dst_ip);
	PyObject *args = PyTuple_Pack(2, py_src, py_dst);

	PyObject *result = PyObject_CallObject(create_ip_header_func, args);

	if (!result || !PyList_Check(result))
	{
		printf("Error: Python function did not return a list\n");
		goto error;
	}

	int size = convert_python_list_to_c_array(result, ip_bytes, 20); // Default IP header size
	if (size < 0)
	{
		printf("Error converting Python list to C array\n");
		goto error;
	}

	*ip_len = size;

	Py_DECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_src);
	Py_DECREF(py_dst);
	return 0;

error:
	Py_XDECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_src);
	Py_DECREF(py_dst);
	return -1;
}
int create_udp_header_c(int sport, int dport, int payload_len,
						unsigned char *udp_bytes, int *udp_len)
{
	PyObject *py_sport = PyLong_FromLong(sport);
	PyObject *py_dport = PyLong_FromLong(dport);
	PyObject *py_len = PyLong_FromLong(8 + payload_len); // UDP header = 8 bytes

	PyObject *args = PyTuple_Pack(3, py_sport, py_dport, py_len);

	PyObject *result = PyObject_CallObject(create_udp_header_func, args);

	if (!result || !PyList_Check(result))
	{
		printf("Error: Python function did not return a list\n");
		goto error;
	}

	int size = convert_python_list_to_c_array(result, udp_bytes, 8);
	if (size < 0)
	{
		printf("Error converting Python list to C array\n");
		goto error;
	}

	*udp_len = size;

	Py_DECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_sport);
	Py_DECREF(py_dport);
	Py_DECREF(py_len);
	return 0;

error:
	Py_XDECREF(result);
	Py_DECREF(args);
	Py_DECREF(py_sport);
	Py_DECREF(py_dport);
	Py_DECREF(py_len);
	return -1;
}


extern "C" __declspec(dllexport) int arp_frame(const svOpenArrayHandle data, int *len,
											   const char *src_mac, const char *src_ip,
											   const char *dst_mac, const char *dst_ip)
{

	unsigned char *arr_ptr = (unsigned char *)svGetArrayPtr(data);
	if (!arr_ptr)
	{
		std::cout << "Null pointer received\n";
		return -1;
	}

	init_python_wrapper();

	unsigned char arp_bytes[28];
	int arp_len = 0;

	// Use the input strings from SV
	create_arp_frame_c(src_mac, src_ip, dst_mac, dst_ip, arp_bytes, &arp_len);

	cleanup_python_wrapper();

	// Copy the generated ARP bytes to SystemVerilog array
	for (int i = 0; i < arp_len; ++i)
	{
		arr_ptr[i] = arp_bytes[i];
	}

	*len = arp_len;
	return 0;
}

extern "C" __declspec(dllexport) int eth_frame(const svOpenArrayHandle data, int *len,
                                               const char *src_mac, const char *dst_mac,
                                               int eth_type)
{
    unsigned char *arr_ptr = (unsigned char *)svGetArrayPtr(data);
    if (!arr_ptr)
    {
        std::cout << "Null pointer received\n";
        return -1;
    }

    init_python_wrapper();

    unsigned char eth_bytes[14]; // Ethernet header = 14 bytes
    int eth_len = 0;

    create_eth_frame_c(src_mac, dst_mac, eth_bytes, &eth_len);

    cleanup_python_wrapper();

    for (int i = 0; i < eth_len; ++i)
    {
        arr_ptr[i] = eth_bytes[i];
    }

    *len = eth_len;
    return 0;
}

extern "C" __declspec(dllexport) int ip_header(const svOpenArrayHandle data, int *len,
                                               const char *src_ip, const char *dst_ip,
                                               int proto)
{
    unsigned char *arr_ptr = (unsigned char *)svGetArrayPtr(data);
    if (!arr_ptr)
    {
        std::cout << "Null pointer received\n";
        return -1;
    }

    init_python_wrapper();

    unsigned char ip_bytes[20]; // Minimum IP header size = 20 bytes
    int ip_len = 0;

    create_ip_header_c(src_ip, dst_ip, ip_bytes, &ip_len);

    cleanup_python_wrapper();

    for (int i = 0; i < ip_len; ++i)
    {
        arr_ptr[i] = ip_bytes[i];
    }

    *len = ip_len;
    return 0;
}

extern "C" __declspec(dllexport) int udp_header(const svOpenArrayHandle data, int *len,
                                                int sport, int dport, int payload_len)
{
    unsigned char *arr_ptr = (unsigned char *)svGetArrayPtr(data);
    if (!arr_ptr)
    {
        std::cout << "Null pointer received\n";
        return -1;
    }

    init_python_wrapper();

    unsigned char udp_bytes[8]; // UDP header size = 8 bytes
    int udp_len = 0;

    create_udp_header_c(sport, dport, payload_len, udp_bytes, &udp_len);

    cleanup_python_wrapper();

    for (int i = 0; i < udp_len; ++i)
    {
        arr_ptr[i] = udp_bytes[i];
    }

    *len = udp_len;
    return 0;
}


int main()
{
	init_python_wrapper();

	// ARP Frame
	unsigned char arp[28];
	int arp_len;
	if (create_arp_frame_c("02:00:00:00:00:01", "192.168.1.100", "ff:ff:ff:ff:ff:ff", "192.168.1.1", arp, &arp_len) == 0)
	{
		printf("ARP Frame (%d bytes):\n", arp_len);
		for (int i = 0; i < arp_len; i++) printf("%02x ", arp[i]);
		printf("\n");
	}

	// Ethernet Frame
	unsigned char eth[14];
	int eth_len;
	if (create_eth_frame_c("02:00:00:00:00:01", "ff:ff:ff:ff:ff:ff", eth, &eth_len) == 0)
	{
		printf("ETH Header (%d bytes):\n", eth_len);
		for (int i = 0; i < eth_len; i++) printf("%02x ", eth[i]);
		printf("\n");
	}

	// IP Header
	unsigned char ip[20];
	int ip_len;
	if (create_ip_header_c("192.168.1.100", "192.168.1.1", ip, &ip_len) == 0)
	{
		printf("IP Header (%d bytes):\n", ip_len);
		for (int i = 0; i < ip_len; i++) printf("%02x ", ip[i]);
		printf("\n");
	}

	// UDP Header
	unsigned char udp[8];
	int udp_len;
	if (create_udp_header_c(1234, 5678, 10, udp, &udp_len) == 0)
	{
		printf("UDP Header (%d bytes):\n", udp_len);
		for (int i = 0; i < udp_len; i++) printf("%02x ", udp[i]);
		printf("\n");
	}

	cleanup_python_wrapper();
	return 0;
}
