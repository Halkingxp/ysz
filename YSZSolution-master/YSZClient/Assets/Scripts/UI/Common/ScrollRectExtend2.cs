using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;

/// <summary>
/// ScrollRect 扩展2
/// </summary>
public class ScrollRectExtend2 : UnityEngine.UI.ScrollRect, IPointerDownHandler, IPointerUpHandler
{
    /// <summary>
    /// 是否响应点击事件
    /// </summary>
    bool mIsResponseClick = true;
    int mPointerId = int.MinValue;

    /// <summary>
    /// 响应被点击事件
    /// </summary>
    public UnityEvent onClick = null;

    /// <summary>
    /// Drag 事件
    /// </summary>
    /// <param name="eventData"></param>
    public override void OnDrag(PointerEventData eventData)
    {
        if (eventData.pointerId == mPointerId)
        {
            mIsResponseClick = false;
        }
        base.OnDrag(eventData);
    }

    /// <summary>
    /// 按下状态
    /// </summary>
    /// <param name="eventData"></param>
    public void OnPointerDown(PointerEventData eventData)
    {
        if (mPointerId == int.MinValue)
        {
            mPointerId = eventData.pointerId;
            mIsResponseClick = true;
        }
    }

    /// <summary>
    /// 抬起状态
    /// </summary>
    /// <param name="eventData"></param>
    public void OnPointerUp(PointerEventData eventData)
    {
        if (eventData.pointerId == mPointerId)
        {
            if (mIsResponseClick && eventData.position == eventData.pressPosition)
            {
                if (onClick != null)
                {
                    onClick.Invoke();
                }
            }
            mPointerId = int.MinValue;
            mIsResponseClick = true;
        }
    }


}