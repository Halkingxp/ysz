//***************************************************************
// 脚本名称：Master.cs
// 类创建人：周  波
// 创建日期：2017.02
// 功能描述：主角信息
//***************************************************************

using UnityEngine;

public partial class Master
{
    static Master m_Instance = null;

    internal Master()
    {
    }

    /// <summary>
    /// Master 数据的实例
    /// </summary>
    public Master Instance
    {
        get
        {
            return m_Instance;
        }
    }

}
