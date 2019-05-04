// #<{(|****************************************************************************
// Copyright (C), 2013-2015, ***. Co., Ltd.
// 文 件 名:  ScriptMgr.cpp
// 作    者:     
// 版    本:  1.0
// 完成日期:  2013-11-14
// 说明信息:  脚本管理器, 调用python脚本
// ****************************************************************************|)}>#
// #include "ScriptPython.h"
//
//
// #if defined (ACE_HAS_EVENT_POLL) || defined (ACE_HAS_DEV_POLL)
// #include "python2.7/Python.h"
// #else
// #include "Python.h"
// #endif
//
//
// CScriptPython::CScriptPython(void)
// {
// }
//
// CScriptPython::~CScriptPython(void)
// {
// 	
// }
//
// CScriptPython& CScriptPython::GetInstance(void)
// {
//     static CScriptPython object;
//     return object;
// }
//
// /#<{(|*******************************************************************
// //函数功能: 初始化脚本管理器
// //第一参数: 
// //返回说明: 返回0,  初始化成功
// //返回说明: 返回-1, 初始化失败
// //备注说明: 
// /#<{(|*******************************************************************
// int CScriptPython::Initialize(const char *szPath)
// {
// 	if (szPath == NULL)
// 	{
// 		return -1;
// 	}
//
// 	char szFullPath[256] = {};
// 	sprintf(szFullPath, "sys.path.append('%s')", szPath);
//
// 	m_cPath = szFullPath;
// 	printf("脚本文件路径: %s\r\n", szFullPath);
// 	return 0;
// }
//
// /#<{(|*******************************************************************
// //函数功能: 调用脚本
// //第一参数: [IN]  脚本文件名,不要.py
// //第二参数: [IN]  调用函数名
// //第三参数: [IN]  调用函数的参数包
// //第死参数: [OUT] 输出的参数包
// //返回说明: 返回true,  调用成功
// //返回说明: 返回false, 调用失败
// //备注说明: 输入参数，第一个为string, 参数的 格式:类似"isi"，后面跟参数。
// /#<{(|*******************************************************************
// bool CScriptPython::CallScript(const String &strScript, const String &strFunction, CPacket *pInParam #<{(| = NULL |)}>#, CPacket *pOutParam #<{(| = NULL |)}>#)
// {
// 	Py_Initialize();  
// 	if (!Py_IsInitialized())
// 	{
// 		return false;
// 	}
//
// 	PyRun_SimpleString("import sys");
// 	PyRun_SimpleString(m_cPath.c_str());
//
// 	// 导入模块
// 	PyObject *pModule = PyImport_ImportModule(strScript.c_str()); 
// 	if (pModule == NULL) 
// 	{
// 		PyErr_Print();
// 		Py_Finalize();
// 		return false;
// 	}
//
// 	PyObject* pyParams = NULL;
// 	if (NULL != pInParam)
// 	{
// 		String format = pInParam->ReadString();
// 		if (!format.empty())
// 		{
// 			pyParams = PyTuple_New(format.size());
// 			if (NULL == pyParams)
// 			{
// 				PyErr_Print();
// 				Py_Finalize();
// 				return false;
// 			}
// 			for (uint32 i = 0 ; i < format.size(); ++i)
// 			{
// 				PyObject* pyParams1 = NULL;
// 				char _format = format[i];
// 				if ('i' == _format)
// 				{
// 					uint32 n = pInParam->ReadUint32();
// 					pyParams1 = Py_BuildValue("i",n);
//
// 				}
// 				else if ('s' == _format)
// 				{
// 					String s = pInParam->ReadString();
// 					pyParams1 = Py_BuildValue("s", s.c_str());
// 				}
// 				else
// 				{
// 					PyErr_Print();
// 					Py_Finalize();
// 					return false;
// 				}
//
// 				if (NULL == pyParams1)
// 				{
// 					PyErr_Print();
// 					Py_Finalize();
// 					return false;
// 				}
// 				PyTuple_SetItem(pyParams, i, pyParams1);
// 			}
// 		}
//
// 	}
// 	
// 		
// 	//// 调用函数
// 	PyObject* pFun = PyObject_GetAttrString(pModule, strFunction.c_str());
// 	PyObject* pOut = NULL;
// 	PyErr_Print();
// 	pOut = PyEval_CallObject(pFun, pyParams);
// 	PyErr_Print();
// 	#<{(|
// 	if (NULL == pyParams)
// 	{
// 		pOut = PyObject_CallFunction(pFun, NULL);
// 	}
// 	else
// 	{
// 		pOut = PyEval_CallObject(pFun, pyParams);
// 	}
// 	|)}>#
// 	printf("%s,%s\n", strScript.c_str(), strFunction.c_str());
// 	if (NULL != pOut)
// 	{
// 		//PyString_AsString(pOut);
// 		Py_DECREF(pOut);
// 	}
//
// 	Py_XDECREF(pFun);
// 	Py_XDECREF(pyParams);
// 	Py_XDECREF(pModule);
// 	PyErr_Print();
// 	Py_Finalize();
// 	return true;
// }
//
// bool CScriptPython::CallScriptTokenList(const String &strScript, const String &strFunction, std::vector<String>& token)
// {
// 	Py_Initialize();  
// 	if (!Py_IsInitialized())
// 	{
// 		return false;
// 	}
//
// 	PyRun_SimpleString("import sys");
// 	PyRun_SimpleString(m_cPath.c_str());
//
// 	// 导入模块
// 	PyObject *pModule = PyImport_ImportModule(strScript.c_str()); 
// 	if (pModule == NULL) 
// 	{
// 		PyErr_Print();
// 		Py_Finalize();
// 		return false;
// 	}
//
// 	PyObject* pList = PyList_New(token.size());
// 	PyObject *args = PyTuple_New(1);
// 	if (NULL == pList || NULL == args)
// 	{
// 		PyErr_Print();
// 		Py_Finalize();
// 		return false;
// 	}
//
// 	for(int i = 0; i < (int)token.size(); ++i)
// 	{
// 		PyList_SetItem(pList, i, Py_BuildValue("s", token[i].c_str()));
// 	}
// 	PyTuple_SetItem(args, 0, pList);
// 	
// 	//// 调用函数
// 	PyObject* pFun = PyObject_GetAttrString(pModule, strFunction.c_str());
// 	PyObject* pOut = NULL;
// 	PyErr_Print();
// 	pOut = PyEval_CallObject(pFun, args);
// 	PyErr_Print();
// 	if (NULL != pOut)
// 	{
// 		//PyString_AsString(pOut);
// 		Py_DECREF(pOut);
// 	}
//
// 	Py_XDECREF(pFun);
// 	Py_XDECREF(args);
// 	Py_XDECREF(pModule);
// 	PyErr_Print();
// 	Py_Finalize();
// 	return true;
// }
