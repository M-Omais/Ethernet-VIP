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
	printf("Importing xgmii_functions module...\n");
	arp_module = PyImport_ImportModule("arp_function");
	if (!arp_module)
	{
		printf("Error importing module:\n");
		PyErr_Print();

		// Check if module exists
		PyObject *module_name = PyUnicode_FromString("xgmii_functions");
		if (PyImport_Import(module_name) == NULL)
		{
			printf("Module xgmii_functions cannot be imported. Check these locations:\n");
			for (int i = 0; i < PyList_Size(sys_path); i++)
			{
				PyObject *item = PyList_GetItem(sys_path, i);
				const char *path = PyUnicode_AsUTF8(item);
				if (path)
				{
					printf("  - %s/xgmii_functions.py\n", path);
				}
			}
		}
		Py_XDECREF(module_name);
		return -1;
	}

	// Get function references
	create_arp_frame_func = PyObject_GetAttrString(arp_module, "create_arp_frame");
	// parse_xgmii_frame_func = PyObject_GetAttrString(arp_module, "parse_xgmii_frame");

	if (!create_arp_frame_func)
	{
		printf("Error getting functions:\n");
		PyErr_Print();
		return -1;
	}

	printf("Python wrapper initialized successfully\n");
	return 0;
}
void cleanup_python_wrapper()
{
	if (create_arp_frame_func)
		Py_DECREF(create_arp_frame_func);
	Py_Finalize();
}

int convert_python_list_to_c_array(PyObject *py_list, void *c_array, int max_size, int is_control)
{
	if (!PyList_Check(py_list))
	{
		printf("Error: Python object is not a list\n");
		return -1;
	}

	int list_size = PyList_Size(py_list);
	if (list_size > max_size)
	{
		printf("Error: List too large for C array\n");
		return -1;
	}

	for (int i = 0; i < list_size; i++)
	{
		PyObject *item = PyList_GetItem(py_list, i);
		if (!PyLong_Check(item))
		{
			printf("Error: List item %d is not an integer\n", i);
			return -1;
		}

		if (is_control)
		{
			// Use 64-bit integers for conversion
			unsigned long long val = PyLong_AsUnsignedLongLong(item);
			if (val == (unsigned long long)-1 && PyErr_Occurred())
			{
				printf("Error converting control value at index %d: ", i);
				PyErr_Print();

				// Debug: Print the problematic value
				PyObject *str_val = PyObject_Str(item);
				if (str_val)
				{
					const char *s = PyUnicode_AsUTF8(str_val);
					printf("Problematic control value: %s\n", s);
					Py_DECREF(str_val);
				}
				return -1;
			}
			if (val > 0xFF)
			{
				printf("Error: Control value out of range [0-255] at %d: %llu\n", i, val);
				return -1;
			}
			((unsigned char *)c_array)[i] = (unsigned char)val;
		}
		else
		{
			((uint64_t *)c_array)[i] = PyLong_AsUnsignedLongLong(item);
			if (PyErr_Occurred())
			{
				printf("Error converting data value at index %d: ", i);
				PyErr_Print();
				return -1;
			}
		}
	}
	return list_size;
}


int create_arp_frame_c(const char *hwsrc, const char *psrc,
                       const char *hwdst, const char *pdst,
                       unsigned char *arp_bytes, int *arp_len)
{
    // Convert arguments to Python strings
    PyObject *py_hwsrc = PyUnicode_FromString(hwsrc);
    PyObject *py_psrc  = PyUnicode_FromString(psrc);
    PyObject *py_hwdst = PyUnicode_FromString(hwdst);
    PyObject *py_pdst  = PyUnicode_FromString(pdst);

    // Pack arguments into a Python tuple
    PyObject *args = PyTuple_Pack(4, py_hwsrc, py_psrc, py_hwdst, py_pdst);

    // Call the Python function (must be already imported and initialized)
    PyObject *result = PyObject_CallObject(create_arp_frame_func, args);

    if (!result || !PyList_Check(result)) {
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
    int size = convert_python_list_to_c_array(result, arp_bytes, 1500, 1); // max ARP size
    if (size < 0) {
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

extern "C" __declspec(dllexport) int helloFromCppArray(const svOpenArrayHandle data, int* len,
                      const char* src_mac, const char* src_ip,
                      const char* dst_mac, const char* dst_ip) {

    unsigned char* arr_ptr = (unsigned char*) svGetArrayPtr(data);
    if (!arr_ptr) {
        std::cout << "Null pointer received\n";
        return -1;
    }

    init_python_wrapper();

    unsigned char arp_bytes[1500];
    int arp_len = 0;

    // Use the input strings from SV
    create_arp_frame_c(src_mac, src_ip, dst_mac, dst_ip, arp_bytes, &arp_len);

    cleanup_python_wrapper();

    // Copy the generated ARP bytes to SystemVerilog array
    for (int i = 0; i < arp_len; ++i) {
        arr_ptr[i] = arp_bytes[i];
    }

    *len = arp_len;
    return 0;
}




int main()
{
	init_python_wrapper();
	unsigned char arp_bytes[1500];  // Buffer to store the generated ARP frame
	int arp_len = 0;                // Variable to store the length of the ARP frame
	create_arp_frame_c("02:00:00:00:00:01", "192.168.1.100", "ff:ff:ff:ff:ff:ff", "192.168.1.1", arp_bytes, &arp_len);
	// for (int i = 0; i < arp_len; i++)
	// {
	// 	printf("%02x\t", arp_bytes[i]);
	// }
	printf("\n");
	cleanup_python_wrapper();
	return 0;
}