/*    
 * Copyright (c) 2015.5 , Yongda Chen 411416311@qq.com
 * All rights reserved.
 * Use, modification and distribution are subject to the "New BSD License"
 * 测试已经适用于VS插件 BabeLua
*/

using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.IO;



public class ExportLuaSyntax  {
    public static string CLASS_FOAMART = "{1} = class({1})\n"; 
    //ClassMethodInfo
	public class ClassMethodInfo{
		public static string HELP_FORMART =
			@"
--- <summary>
--- 全名:{0}{1}{2}
--- 返回值 : {3}
--- </summary>";

		public static string HELP_PARA_FORMAT = "\n--- arg[{0}] : {1}";
		public static string HELP_OVERRIDE_FORMAT = "\n--- 重载{0} :\n";
		public static string HELP_FUN_FORMAT = "--- function {0}{1}{2}({3}) end";
		public static string HELP_RETURN_FORMAT = "\n--- <returns type=\"{0}\"></returns>";
		public static string FUNCTION_FORMAT = "\nfunction {0}{1}{2}({3}) end";
		public static string FUNC_PARA_FORMAT = "--- arg[{0}] : {1}\n";
        public static string PF_FORMAT = "\n{0}.{1} = function() end";
        public static string PF_STATE = "[{0}]";

		
		public string fullName;
		public string className;
		public string name;
		public List< List< KeyValuePair<string,string> > >  overrideList = new List< List<KeyValuePair<string, string>> >();		
		public bool isStatic ;
        public bool isCanRead;
        public bool isCanWrite;
        public bool isPf = false;
        private string returnName_;
        public string returnName {
            get { return returnName_; }
            set {
                if (string.IsNullOrEmpty(returnName_) || returnName_ == "Void") {
                    returnName_ = value;
                }
            }
        }

        public void DisposReturnName() {
            returnName_ = returnName_.EndsWith("[]") ? "Array" : returnName_;
        }

		public string Desc(bool isLog){
            DisposReturnName();
            if (isPf){
                return DescPf(isLog);
            }
            else {
                return DescMethod(isLog);
            }
		}

        public string DescPf(bool isLog) {
            string strIsStatic = isStatic ? " [静态] " : "";
            string strReadWrite = isCanRead && isCanWrite ? " [读写] " : "";
            string strCanRead = isCanRead ? " [只读] " : "";
            string strCanWrite = isCanWrite ? " [只写] " : "";
            string midStr = isCanRead && isCanWrite ? strReadWrite : strCanRead + strCanWrite;
            string helpStr = string.Format(HELP_FORMART, fullName, strIsStatic, midStr, returnName);
            string func = string.Format(PF_FORMAT, className, name);
            string returnStr = string.Format(HELP_RETURN_FORMAT, returnName);
            string all = helpStr + returnStr + func;
            return all;
        }

        public string DescMethod(bool isLog) {
            string argStr = string.Empty;
            string symbol = isStatic ? "." : ":";
            for (int a = 0; a < overrideList.Count; a++)
            {
                var paraNameList = overrideList[a];
                string paraArg = string.Empty;
                string paraStr = string.Empty;
                string overrideTile = overrideList.Count == 1 ? "\n" : string.Format(HELP_OVERRIDE_FORMAT, a);
                for (int i = 0; i < paraNameList.Count; i++)
                {
                    string argHelp = paraNameList[i].Key + " " + paraNameList[i].Value;
                    //string argFunc = paraNameList[i].Key + "_" + paraNameList[i].Value; 
                    paraArg += i == 0 ? argHelp : "," + argHelp;
                    paraStr += string.Format(HELP_PARA_FORMAT, i, argHelp);
                }
                string funcStr = string.Format(HELP_FUN_FORMAT, className, symbol, name, paraArg);
                argStr += overrideTile + funcStr + paraStr;
            }
            string strIsStatic = isStatic ? " [静态] " : "";
            string helpStr = string.Format(HELP_FORMART, fullName, strIsStatic, argStr, returnName);
            string returnStr = string.Format(HELP_RETURN_FORMAT, returnName);
            string func = string.Format(FUNCTION_FORMAT, className, symbol, name, "");
            string all = helpStr + returnStr + func;
            if (isLog)
            {
                Debug.Log(all);
            }
            return all;
        }
	}
    static Dictionary<string, System.Type> dict = new Dictionary<string, System.Type>();
    public static BindingFlags BindingFlags = BindingFlags.Public | BindingFlags.Static | BindingFlags.IgnoreCase;
    public static bool IsUseFullName = true;
    public static string PrefixNamespace = "CS.";

	public static string Export(System.Type type){
		if (!type.IsGenericType && type.BaseType != typeof(System.MulticastDelegate) &&
		    !typeof(YieldInstruction).IsAssignableFrom(type) )
		{
            string typeName = GetTypeName(type);
			Dictionary<string,ClassMethodInfo> cmfDict = new Dictionary<string,ClassMethodInfo>();

            DisposCtor(type,cmfDict);
            DisposMethods(type,cmfDict);
            DisposProperties(type,cmfDict);
            DisposField(type,cmfDict);
            //PropertyInfo[] propertyArray = type.GetProperties();            
            string classStr = string.Format(CLASS_FOAMART, typeName, typeName);// +string.Format(CLASS_FOAMART, aliasName, aliasName);
           // string newFuncStr = string.Format(CONSTRUCOR_FORMAT, typeName, typeName, typeName);
            string content = classStr ;
			foreach(ClassMethodInfo f in cmfDict.Values){
				content +=f.Desc(false);
			}
            return content;
		}
        return "";
	}

    public static void DisposField(System.Type type, Dictionary<string, ClassMethodInfo> cmfDict) {
       FieldInfo[] array =  type.GetFields(BindingFlags.GetField | BindingFlags.SetField | BindingFlags.Instance | BindingFlags);
       foreach (FieldInfo info in array)
       {
           string key = type.Namespace + "." + type.Name + "." + info.Name;
           ClassMethodInfo cmf = !cmfDict.ContainsKey(key) ? new ClassMethodInfo() : cmfDict[key];
           cmf.fullName = key;
           cmf.className = GetTypeName(type);
           cmf.name = info.Name;
           cmf.returnName = GetTypeName(info.FieldType);
           cmf.isStatic = info.IsStatic;
           cmf.isCanRead = true;
           cmf.isCanWrite = true;
           cmf.isPf = true;
           cmfDict[key] = cmf;
       }
    }

    public static void DisposProperties(System.Type type, Dictionary<string, ClassMethodInfo> cmfDict)
    {
        PropertyInfo[] array = type.GetProperties(BindingFlags | BindingFlags.GetProperty | BindingFlags.SetProperty | BindingFlags.Instance | BindingFlags.FlattenHierarchy);
        foreach(PropertyInfo info in array){
            string key = type.Namespace + "." + type.Name + "." + info.Name;
            ClassMethodInfo cmf = !cmfDict.ContainsKey(key) ? new ClassMethodInfo() : cmfDict[key];
            cmf.fullName = key;
            cmf.className = GetTypeName(type);
            cmf.name = info.Name;
            cmf.returnName = GetTypeName(info.PropertyType);
            cmf.isStatic = false;
            cmf.isCanRead = info.CanRead;
            cmf.isCanWrite = info.CanRead;
            cmf.isPf = true;
            cmfDict[key] = cmf;
        }       
    }

    public static void DisposCtor(System.Type type, Dictionary<string, ClassMethodInfo> cmfDict)
    {
        string fullNamePrefix = type.Namespace + "." + type.Name + "." +  "New";
        string newStr = "New";
        ConstructorInfo[] ctorArray = type.GetConstructors(BindingFlags.Instance | BindingFlags);
        foreach (ConstructorInfo cInfo in ctorArray)
        {            
            ClassMethodInfo ctorCmf = !cmfDict.ContainsKey(newStr) ? new ClassMethodInfo() : cmfDict[newStr];
            ctorCmf.fullName = fullNamePrefix + newStr;
            ctorCmf.className = GetTypeName(type);
            ctorCmf.name = newStr;
            ctorCmf.returnName = GetTypeName(type);
            ctorCmf.isStatic = true;
            cmfDict[newStr] = ctorCmf;
            ctorCmf.overrideList.Add(DisposMethodArgs(cInfo.GetParameters()));
        }

    }

	public static void DisposMethods(System.Type type,Dictionary<string,ClassMethodInfo> cmfDict){
        BindingFlags options = BindingFlags | BindingFlags.Instance | BindingFlags.FlattenHierarchy;
        MethodInfo[] infoArray = type.GetMethods(options);

		foreach(MethodInfo info in infoArray){
			if(info.IsGenericMethod) continue;			
			if(info.Name.IndexOf('_') > 0 ) continue;
			string key = type.Namespace +"." + type.Name +"."+ info.Name;
			ClassMethodInfo cmf = !cmfDict.ContainsKey(key)?  new ClassMethodInfo() :cmfDict[key];
			cmf.fullName =  key;
            cmf.className = GetTypeName(type);
			cmf.name = 	info.Name;
            cmf.returnName = GetTypeName(info.ReturnType);
			cmf.isStatic = info.IsStatic;
			cmfDict[key] = cmf;
            cmf.overrideList.Add(DisposMethodArgs( info.GetParameters() ) );
		}
	}

    public static List<KeyValuePair<string, string>> DisposMethodArgs(ParameterInfo[] pInfoArray)
    {
        List<KeyValuePair<string, string>> tmpList = new List<KeyValuePair<string, string>>();
        foreach (ParameterInfo pInfo in pInfoArray)
        {
            KeyValuePair<string, string> pair = new KeyValuePair<string, string>(pInfo.ParameterType.Name, pInfo.Name);
            tmpList.Add(pair);
        }
        return tmpList;
    }

    public static string GetTypeName(System.Type type)
    {
        string typeName = type.Name;
        if (IsUseFullName)
            typeName = type.UnderlyingSystemType.ToString();
        typeName = PrefixNamespace + typeName;
        return typeName;
    }

    [MenuItem("XLua/ExportLuaSyntax",false,-100)]
    public static void ExportLua()
    {
        dict.Clear();
        AddSystemType();

        //for (int i = 0; i < HotfixConfig.HotfixTypes.Count; i++ )
        //{
        //    var type = HotfixConfig.HotfixTypes[i];
        //    Add(type);
        //}

        for (int i = 0; i < CustomGenConfig.LuaCallCSharp.Count; i++)
        {
            var type = CustomGenConfig.LuaCallCSharp[i];
            Add(type);
        }


        string luaPath = GetBabeLuaPath();
        if (!Directory.Exists(luaPath))
            Directory.CreateDirectory(luaPath);
        foreach(var path in Directory.GetFiles(luaPath,"U3DApi*.lua")){
            File.Delete(path);
        }

        AddXLuaFunc();
        foreach(var type in dict.Values){
            string text =  Export(type);
            try
            {
                string fileName = Path.Combine(luaPath, "U3DApi_" + GetTypeName(type) + ".lua");
                File.WriteAllText(fileName, text, System.Text.Encoding.UTF8);
            }catch(System.Exception ex){
                Debug.LogError("[ExportLuaSyntax] error : typeName :" + GetTypeName(type) + " ex:\n" + ex.ToString());
            }
        }
	}

    static void AddSystemType() {
        Add(typeof(int));
        Add(typeof(char));
        Add(typeof(short));
        Add(typeof(float));
        Add(typeof(string));
        Add(typeof(ulong));
        Add(typeof(long));
        Add(typeof(uint));
        Add(typeof(System.DateTime));
        Add(typeof(System.IO.File));
        Add(typeof(System.IO.Directory));
        Add(typeof(System.TimeSpan));
        Add(typeof(System.Array));
        Add(typeof(System.Type));
    }

    public static void AddXLuaFunc() {
        string text = @"xlua = class(xlua)
xlua.hotfix = function(class, fieldName, func) end;
xlua.access = function(class,fieldName,value) end;
xlua.private_accessible = function(class) end;
xlua.cast = function(instance,class) end;
xlua.load_assembly = function(assemblyName) end;
--[Comment]
--return bool
xlua.import_type = function(className) end;
";
        string luaPath = GetBabeLuaPath();
        if (!Directory.Exists(luaPath))
            Directory.CreateDirectory(luaPath);
        string fileName = Path.Combine(luaPath, "U3DApi_" + "xLua.lua");
        File.WriteAllText(fileName, text, System.Text.Encoding.UTF8);
    }

    public static string GetBabeLuaPath() {
         string myDocPath = System.Environment.GetFolderPath( System.Environment.SpecialFolder.MyDocuments);
        myDocPath = myDocPath.Replace('\\','/');
        string path = myDocPath + "/BabeLua/Completion";
        return path;
    }

    public static void Add(System.Type type) {
        if (type.Name.Contains("<") || type.Name.Contains("$"))
            return;
        if (!dict.ContainsKey(type.ToString())) {
            dict.Add(type.ToString(), type);
        }
    }
}
