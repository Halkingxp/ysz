using System.Collections.Generic;
using UnityEngine;
using System;

/// <summary>
/// 切牌控制
/// </summary>
public class CutDeckControl : MonoBehaviour
{
    /// <summary>
    /// DeckNum
    /// </summary>
    public int DeckNum = 10;
    /// <summary>
    /// 
    /// </summary>
    public int Spacing = 10;
    /// <summary>
    /// 
    /// </summary>
    public float CutInTime = 2f;
    /// <summary>
    /// 
    /// </summary>
    public float SwitchTime = 2f;
    /// <summary>
    /// 
    /// </summary>
    public float ReturnDeskTime = 0.5f;
    /// <summary>
    /// 一叠牌的厚度
    /// </summary>
    public int deckHight = 40;
    /// <summary>
    /// 牌图片的高度
    /// </summary>
    int deckImageHight = 180;
    /// <summary>
    /// 牌靴图片的高度
    /// </summary>
    int cutImageHight = 124;
    /// <summary>
    /// 牌集的默认x坐标
    /// </summary>
    public int DeckPointX = -240;
    /// <summary>
    /// 牌靴的默认x坐标
    /// </summary>
    public int CutPointX = 0;
    /// <summary>
    /// 交换时往右移动的位置
    /// </summary>
    public int SwitchPointX = 0;
    /// <summary>
    /// 
    /// </summary>
    public Vector2 deskPoint = new Vector2(344, 422);
    /// <summary>
    /// 动画结束回调
    /// </summary>
    public Action OnAnimationEnd;

    List<Transform> m_Decks = new List<Transform>();
    public Transform m_deckItem;
    public DragPokerShot m_drag;
    public Transform m_content;
    RectTransform m_dragRect;

    /// <summary>
    /// 牌的结合点
    /// </summary>
    public RectTransform TargetPoint = null;

    int m_index;
    public bool IsSelfCut { get; set; }
    public bool IsDirectFlyToDesk { get; set; }

    bool isInit = false;

    void Init()
    {
        if (isInit == false)
        {
            ItemMoveScript moveScrpit = m_drag.GetComponent<ItemMoveScript>();
            if (moveScrpit == null)
            {
                moveScrpit = m_drag.gameObject.AddComponent<ItemMoveScript>();
            }

            deckImageHight = (int)(m_deckItem.GetComponent<RectTransform>().sizeDelta.y);
            cutImageHight = (int)(m_drag.GetComponent<RectTransform>().sizeDelta.y);
            Debug.LogFormat("deckImageHight:{0} cutImageHight:{1}", deckImageHight, cutImageHight);
            m_dragRect = m_drag.GetComponent<RectTransform>();
            //m_drag.upLimit = (deckImageHight - cutImageHight) / 2 * -1;
            //m_drag.downLimit = m_drag.upLimit + (DeckNum - 2) * deckHight * -1;
            m_drag.upLimit = Spacing * -1;
            m_drag.downLimit = Spacing * (DeckNum - 1) * -1;
            if (m_content.GetComponent<ScaleChangeScript>() == null)
            {
                m_content.gameObject.AddComponent<ScaleChangeScript>();
            }
            if (m_content.GetComponent<ItemMoveScript>() == null)
            {
                m_content.gameObject.AddComponent<ItemMoveScript>();
            }
            if (m_content.GetComponent<RotationChangeScript>() == null)
            {
                m_content.gameObject.AddComponent<RotationChangeScript>();
            }
            isInit = true;
        }
    }

    void CreateObject1()
    {
        if (m_Decks.Count == 0)
        {
            Transform tempItem;
            for (int i = 0; i < DeckNum; i++)
            {
                tempItem = GameObject.Instantiate(m_deckItem);
                tempItem.gameObject.SetActive(true);
                tempItem.gameObject.name = i.ToString();
                tempItem.SetParent(m_content, false);
                if (tempItem.GetComponent<ItemMoveScript>() == null)
                {
                    tempItem.gameObject.AddComponent<ItemMoveScript>();
                }
                m_Decks.Add(tempItem);
            }
        }
    }

    void DeleteObject1()
    {
        int count = m_drag.transform.childCount;
        for (int i = 0; i < DeckNum; i++)
        {
            GameObject.DestroyObject(m_Decks[i].gameObject);
        }
        m_Decks.Clear();
    }

    void SetPosition1()
    {
        //DestroyComponentOfType<ItemMoveScript>(m_content.gameObject);
        //DestroyComponentOfType<ScaleChangeScript>(m_content.gameObject);

        Vector2 uiPos = Vector2.zero;
        // 重置所有deck的顺序，保证index 0 对应的在最上面        
        for (int i = 0; i < m_Decks.Count; i++)
        {
            m_Decks[i].SetParent(m_content);
            m_Decks[i].SetAsFirstSibling();
            uiPos.x = DeckPointX;
            uiPos.y = i * -deckHight;
            DestroyComponentOfType<ItemMoveScript>(m_Decks[i].gameObject);
            m_Decks[i].GetComponent<RectTransform>().anchoredPosition = uiPos;
        }
        // 重置牌靴的位置
        uiPos.x = CutPointX;
        uiPos.y = m_Decks[0].GetComponent<RectTransform>().anchoredPosition.y - 1 - (DeckNum * Spacing / 2);
        m_dragRect.anchoredPosition = uiPos;
        DestroyComponentOfType<ItemMoveScript>(m_dragRect.gameObject);
        if (IsDirectFlyToDesk == true)
        {
            m_drag.gameObject.SetActive(false);
            MoveToDesk1();
        }
        else
        {
            m_drag.gameObject.SetActive(true);
            if (IsSelfCut == true)
            {
                m_drag.OpenDrag();
                if (m_drag.EventDragEnd == null)
                {
                    m_drag.EventDragEnd = EnterDrag1;
                }
                if (m_drag.EventDragIn == null)
                {
                    m_drag.EventDragIn = DragIn1;
                }
            }
            //m_drag.transform.SetAsFirstSibling();
            int index = (int)(Mathf.Abs(m_dragRect.anchoredPosition.y - m_drag.upLimit)) / deckHight;
            // 调整牌靴的层级
            m_drag.transform.SetSiblingIndex(DeckNum - 1 - index);
        }
    }

    void DestroyComponentOfType<T>(GameObject go) where T : Component
    {
        T script = go.GetComponent<T>();
        if (script != null)
        {
            GameObject.Destroy(script);
        }
    }

    public void ResetToBeginning()
    {
        Init();

        m_content.localEulerAngles = Vector3.zero;
        m_content.localPosition = Vector3.zero;
        m_content.localScale = Vector3.one;
        CreateObject1();
        SetPosition1();
    }

    /// <summary>
    /// 拖拽完成,发送事件通知，告诉lua控制脚本.
    /// </summary>
    void EnterDrag1()
    {
        // 发送事件通知，告诉lua控制脚本，拖拽完成
        int index = (int)(Mathf.Abs(m_dragRect.anchoredPosition.y - m_drag.upLimit)) / deckHight;
        //AutoCutIn();
        EventDispatcher.Instance.TriggerEvent("CutDeckControl_CutOver", index);
    }

    void DragIn1()
    {
        int index = (int)(Mathf.Abs(m_dragRect.anchoredPosition.y - m_drag.upLimit)) / deckHight;
        // 调整牌靴的层级
        m_drag.transform.SetSiblingIndex(DeckNum - 1 - index);
    }

    /// <summary>
    /// 自动切牌
    /// </summary>
    /// <param name="index"></param>
    public void AutoCutIn(int index)
    {
        m_drag.CloseDrag();
        // 调整cut到合适的起始点y方向
        m_index = index;
        //m_dragRect.anchoredPosition = new Vector2(m_dragRect.anchoredPosition.x, m_drag.upLimit + deckHight * m_index * -1);
        m_dragRect.anchoredPosition = new Vector2(m_dragRect.anchoredPosition.x, m_drag.upLimit + Spacing * m_index * -1);
        // 调整cut的层级到合适的位置
        m_drag.transform.SetSiblingIndex(DeckNum - 1 - m_index);
        // 计算出移动的速度
        float speed = (CutPointX - DeckPointX) / CutInTime;
        Vector2 endPoint = new Vector2(DeckPointX, m_dragRect.anchoredPosition.y);
        // 执行移动动画，动画完成会事件通知
        ItemMoveScript moveScript = m_drag.GetComponent<ItemMoveScript>();
        if (moveScript == null)
        {
            moveScript = m_drag.gameObject.AddComponent<ItemMoveScript>();
        }
        moveScript.StartMove(endPoint, speed, OnCutIn1);
    }

    /// <summary>
    /// 切牌超时，获取当前切牌位置，发送给服务器
    /// </summary>
    public void CutTimeOut()
    {
        m_drag.CloseDrag();
        EnterDrag1();
    }

    void OnCutIn1()
    {
        //print("切入结束");
        // 进入交换环节
        SwitchPosition1();
    }

    /// <summary>
    /// 交换环节处理
    /// </summary>
    void SwitchPosition1()
    {
        // 包括牌靴在内，上部的牌，向右方移动，移动完成事件通知
        for (int i = m_index; i >= 0; i--)
        {
            m_Decks[i].SetParent(m_drag.transform, true);
        }
        float speed = (SwitchPointX - DeckPointX) / (SwitchTime / 3);
        //print("speed = " + speed);
        Vector2 endPoint = new Vector2(SwitchPointX, m_dragRect.anchoredPosition.y);
        ItemMoveScript moveScript = m_drag.GetComponent<ItemMoveScript>();
        if (moveScript == null)
        {
            Debug.LogError("m_drag未挂ItemMoveScript脚本");
            return;
        }
        moveScript.StartMove(endPoint, speed, OnMoveToRightEnd1);
    }

    /// <summary>
    /// 向右移动
    /// </summary>
    void OnMoveToRightEnd1()
    {
        // 设置移动牌集的层级低于未移动牌集
        m_drag.transform.SetAsFirstSibling();
        StartDownMove1();
    }

    /// <summary>
    /// 向下移动
    /// </summary>
    void StartDownMove1()
    {
        // 向下方移动，距离为未移动牌的厚度，移动完成事件通知
        float distance = DeckNum * deckHight;
        float speed = distance / (SwitchTime / 3);
        Vector2 endPoint = new Vector2(m_dragRect.anchoredPosition.x, m_dragRect.anchoredPosition.y - distance);
        ItemMoveScript moveScript = m_drag.GetComponent<ItemMoveScript>();
        if (moveScript == null)
        {
            Debug.LogError("m_drag未挂ItemMoveScript脚本");
            return;
        }
        moveScript.StartMove(endPoint, speed, OnMoveToDownEnd1);
    }

    /// <summary>
    /// 向下移动结束
    /// </summary>
    void OnMoveToDownEnd1()
    {
        StartLeftMove1();
    }

    /// <summary>
    /// 向左移动
    /// </summary>
    void StartLeftMove1()
    {
        // 调整m_drag的层级
        m_drag.transform.SetAsFirstSibling();
        // 向左方水平移动，让牌块恢复为一整块状态，移动完成事件通知
        float speed = (SwitchPointX - DeckPointX) / (SwitchTime / 3);
        //print("speed = " + speed);
        Vector2 endPoint = new Vector2(DeckPointX, m_dragRect.anchoredPosition.y);
        ItemMoveScript moveScript = m_drag.GetComponent<ItemMoveScript>();
        if (moveScript == null)
        {
            Debug.LogError("m_drag未挂ItemMoveScript脚本");
            return;
        }
        moveScript.StartMove(endPoint, speed, OnMoveToLeftEnd1);
    }

    /// <summary>
    /// 向左移动结束
    /// </summary>
    void OnMoveToLeftEnd1()
    {
        MoveToDesk1();
    }

    /// <summary>
    /// 进入飞入桌面环节
    /// </summary>
    void MoveToDesk1()
    {
        //print("666666666666666666666");
        // 进入飞入桌面环节
        ScaleChangeScript scaleScript = m_content.GetComponent<ScaleChangeScript>();
        if (scaleScript == null)
        {
            scaleScript = m_content.gameObject.AddComponent<ScaleChangeScript>();
        }
        float scaleEnd = 0.12f;
        float time = ReturnDeskTime;
        scaleScript.StartScale(scaleEnd, time, null);
        ItemMoveScript moveScript = m_content.GetComponent<ItemMoveScript>();
        if (moveScript == null)
        {
            moveScript = m_content.gameObject.AddComponent<ItemMoveScript>();
        }
        RectTransform rectContent = m_content.GetComponent<RectTransform>();
        float speed = (deskPoint - rectContent.anchoredPosition).magnitude / ReturnDeskTime;
        Vector2 endPoint = deskPoint;
        // 所有牌块向指定坐标点移动，移动的过程中逐渐缩小，当到达坐标点的时候，事件通知
        moveScript.StartMove(endPoint, speed, OnMoveToDeskEnd1);

        RotationChangeScript rotationScript = m_content.GetComponent<RotationChangeScript>();
        rotationScript.StartRotation(new Vector3(-50, 80, -40), time, null);
    }

    /// <summary>
    /// 飞入桌面环节结束call
    /// </summary>
    void OnMoveToDeskEnd1()
    {
        // 发送事件通知，告诉lua控制脚本，放回桌面完成
        //print("999999999999999999999");
        EventDispatcher.Instance.TriggerEvent("CutDeckControl_ReturnDeskOver", null);
    }

    void Awake()
    {
        Init();
    }

    // Use this for initialization
    protected void Start()
    {
        // test
        //IsSelfCut = true;
        //ResetToBeginning();
    }

}
