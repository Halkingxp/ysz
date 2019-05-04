using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// 表单控件
/// </summary>
public class TabControl : MonoBehaviour
{
    [SerializeField]
    List<TabItemData> m_TabItemDataList = new List<TabItemData>();

    [SerializeField]
    private int m_CurrentKey = 1;

    /// <summary>
    /// 当前定位页签key
    /// </summary>    
    public int CurrentKey { get { return m_CurrentKey; } }
    /// <summary>
    /// 表单变化事件
    /// </summary>
    public event System.Action<int, int> OnTabChanged;
    /// <summary>
    /// Toggle组
    /// </summary>
    ToggleGroup m_ToggleGroup;


    /// <summary>
    /// 添加一个Tab页
    /// </summary>
    /// <param name="key"></param>
    /// <param name="tabToggle"></param>
    /// <param name="content"></param>
    public void AddTabItem(int key, Toggle tabToggle, GameObject content)
    {
        if (tabToggle == null || content == null)
        {
            Debug.LogErrorFormat("Can't add null value in tab control to gameObject name[{0}], please check it!", name);
            return;
        }

        TabItemData itemData = new TabItemData(key, tabToggle, content);

        BindTabItem(itemData);
    }

    /// <summary>
    /// 重置控件定位到那个元素上
    /// </summary>
    /// <param name="key"></param>
    public bool ResetTabOnItem(int key)
    {
        TabItemData findItem = m_TabItemDataList.Find(item => item.Key == key);
        if (findItem != null)
        {
            findItem.TabTitle.isOn = true;
            return true;
        }
        else
        {
            return false;
        }
    }

    /// <summary>
    /// 数据绑定
    /// </summary>
    /// <param name="itemData"></param>
    void BindTabItem(TabItemData itemData)
    {
        itemData.TabTitle.group = m_ToggleGroup;
        itemData.TabTitle.isOn = false;
        itemData.TabContent.SetActive(false);
        itemData.TabTitle.onValueChanged.AddListener((isOn) => TitleItem_OnValueChanged(isOn, itemData));
    }

    /// <summary>
    /// TitleItem 状态变化
    /// </summary>
    /// <param name="isOn"></param>
    /// <param name="itemData"></param>
    void TitleItem_OnValueChanged(bool isOn, TabItemData itemData)
    {
        if (isOn)
        {
            int preKey = m_CurrentKey;
            m_CurrentKey = itemData.Key;
            itemData.TabContent.SetActive(true);
            NotifyEvent(preKey, m_CurrentKey);
        }
        else
        {
            itemData.TabContent.SetActive(false);
        }
    }
    /// <summary>
    /// 表单变化通知
    /// </summary>
    /// <param name="preKey"></param>
    /// <param name="currentKey"></param>
    void NotifyEvent(int preKey, int currentKey)
    {
        if (OnTabChanged != null)
        {
            OnTabChanged(preKey, currentKey);
        }
    }


    private void Awake()
    {
        m_ToggleGroup = GetComponent<ToggleGroup>();
        if (m_ToggleGroup == null)
        {
            m_ToggleGroup = gameObject.AddComponent<ToggleGroup>();
        }
        m_ToggleGroup.allowSwitchOff = false;

        if (m_TabItemDataList.Count > 0)
        {
            for (int i = 0; i < m_TabItemDataList.Count; i++)
            {
                TabItemData itemData = m_TabItemDataList[i];
                if (itemData == null)
                    continue;
                if (itemData.TabTitle == null || itemData.TabContent == null)
                {
                    Debug.LogErrorFormat("Some tab item data contains null value, please check it, in TabControl script whit gameObject name[{0}]", name);
                    continue;
                }
                BindTabItem(itemData);
            }

            // 设置默认页签
            if (!ResetTabOnItem(m_CurrentKey))
            {
                if (m_TabItemDataList.Count > 0)
                {
                    m_TabItemDataList[0].TabTitle.isOn = true;
                }
            }
        }
    }

}

/// <summary>
/// 表单控件数据
/// </summary>
[System.Serializable]
public class TabItemData
{
    public TabItemData(int key, Toggle title, GameObject content)
    {
        this.Key = key;
        this.TabTitle = title;
        this.TabContent = content;
    }

    [SerializeField]
    private int m_Key = 0;
    /// <summary>
    /// 页签key，，不要和其他重复，通知外部时通知出此
    /// </summary>    
    public int Key
    {
        get { return m_Key; }
        private set { m_Key = value; }
    }

    [SerializeField]
    private UnityEngine.UI.Toggle m_TabTitle = null;
    /// <summary>
    /// 页签选项卡
    /// </summary>    
    public UnityEngine.UI.Toggle TabTitle
    {
        get { return m_TabTitle; }
        private set { m_TabTitle = value; }
    }
    [SerializeField]
    private UnityEngine.GameObject m_TabContent = null;
    /// <summary>
    /// 页签内容
    /// </summary>
    [SerializeField]
    public UnityEngine.GameObject TabContent
    {
        get { return m_TabContent; }
        private set { m_TabContent = value; }
    }
}
