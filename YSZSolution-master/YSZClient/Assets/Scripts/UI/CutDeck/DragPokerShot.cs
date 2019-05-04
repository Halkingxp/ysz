using System;
using UnityEngine;
using UnityEngine.EventSystems;//要想用拖拽事件必须导入EventSystems

public class DragPokerShot : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    /// <summary>
    /// 控制组件
    /// </summary>
    public RectTransform m_rect;
    /// <summary>
    /// 父节点组件
    /// </summary>
    public RectTransform ParentRect;
    /// <summary>
    /// 拖拽事件结束
    /// </summary>
    public Action EventDragEnd;
    /// <summary>
    /// 拖拽事件开始
    /// </summary>
    public Action EventDragIn;
    /// <summary>
    /// 最上一叠牌的y坐标减去一叠牌厚度的一半
    /// </summary>
    public int upLimit = -5;
    /// <summary>
    /// 最下一叠牌的y坐标加上一叠牌厚度的一半
    /// </summary>
    public int downLimit = -100;
    /// <summary>
    /// 一叠牌的厚度
    /// </summary>
    public int deckHalfHight = 10;
    /// <summary>
    /// 是否拖拽tag
    /// </summary>
    bool m_isCanDrag = false;
    /// <summary>
    /// 
    /// </summary>
    float m_startDragY;
    /// <summary>
    /// 
    /// </summary>
    float m_basePosY;


    /// <summary>
    /// 开启拖拽
    /// </summary>
    public void OpenDrag()
    {
        m_isCanDrag = true;
    }
    /// <summary>
    /// 关闭拖拽
    /// </summary>
    public void CloseDrag()
    {
        //print("333333333333333333333333333333333333333333");
        m_isCanDrag = false;
        //if (EventDragEnd != null)
        //{
        //    EventDragEnd.Invoke();
        //}
    }
    /// <summary>
    /// 开始拖拽
    /// </summary>
    /// <param name="eventData"></param>
    public void OnBeginDrag(PointerEventData eventData)//
    {
        //print("111111111111111111111111111111111111111111111");
        // 记录按下点的y坐标
        Vector2 screenPos = eventData.position;
        Vector2 uiPos;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(ParentRect, screenPos, eventData.pressEventCamera, out uiPos);
        m_startDragY = uiPos.y;
        m_basePosY = m_rect.anchoredPosition.y;
    }

    /// <summary>
    /// 拖拽中
    /// </summary>
    /// <param name="eventData"></param>
    public void OnDrag(PointerEventData eventData)//
    {
        if (m_isCanDrag == false)
        {
            return;
        }
        //GetComponent<RectTransform>().pivot.Set(0, 0);
        Vector2 screenPos = eventData.position;
        Vector2 uiPos;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(ParentRect, screenPos, eventData.pressEventCamera, out uiPos);
        uiPos.x = m_rect.anchoredPosition.x;
        float deltaY = uiPos.y - m_startDragY;
        float newY = m_basePosY + deltaY;
        //uiPos.y = uiPos.y - m_startDragY;
        if (newY > upLimit)
        {
            newY = upLimit;
        }
        else if (newY < downLimit)
        {
            newY = downLimit;
        }

        uiPos.y = newY;
        m_rect.anchoredPosition = uiPos;
        if (EventDragIn != null && m_isCanDrag)
        {
            EventDragIn.Invoke();
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        //print("2222222222222222222222222222222222222222222222");
        // 通知控制器，进入自动切入阶段
        if (EventDragEnd != null && m_isCanDrag)
        {
            EventDragEnd.Invoke();
        }
        m_isCanDrag = false;
    }

}
