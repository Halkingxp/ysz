using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

/// <summary>
/// 轮播控件元素
/// </summary>
[XLua.LuaCallCSharp]
public class CoverFlowItem : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IBeginDragHandler, IEndDragHandler, IDragHandler
{
    /// <summary>
    /// 父控件
    /// </summary>
    CoverFlow m_CoverFlow = null;

    /// <summary>
    /// 遮罩元素
    /// </summary>
    Transform m_MaskObject = null;

    /// <summary>
    /// 是否响应点击
    /// </summary>
    bool m_IsResponseClick = true;

    Vector3 m_LocalPointOfPointerDown = Vector3.zero;

    /// <summary>
    /// 手势索引ID
    /// </summary>
    int m_PointerId = int.MinValue;

    /// <summary>
    /// Start index
    /// </summary>
    public int CurveOffSetIndex { get; set; }

    /// <summary>
    /// Curve center offset 
    /// </summary>
    public float CenterOffSet { get; set; }

    /// <summary>
    /// Runtime real index(Be calculated in runtime)
    /// </summary>
    public int RealIndex { get; set; }

    /// <summary>
    /// 是否居中
    /// </summary>
    bool m_IsCenter = false;

    /// <summary>
    /// 通知外部，选中事件
    /// </summary>
    public event Action<bool> OnValueChanged;

    /// <summary>
    /// 居中的元素被点击了
    /// </summary>
    public event Action CenterItemOnClicked;

    void Awake()
    {
        m_MaskObject = this.transform.Find("Mask");
    }

    /// <summary>
    /// 设置空间的轮播控件
    /// </summary>
    /// <param name="coverFlow"></param>
    public void SetCoverFlow(CoverFlow coverFlow)
    {
        this.m_CoverFlow = coverFlow;
    }

    /// <summary>
    /// Set the item center state
    /// </summary>
    /// <param name="isCenter"></param>
    public virtual void SetSelectState(bool isCenter)
    {
        if (m_MaskObject != null)
        {
            m_MaskObject.gameObject.SetActive(!isCenter);
        }
        else
        {
            //this.GetComponent<UnityEngine.UI.Image>().color = isCenter ? Color.white : Color.gray;
        }

        if (m_IsCenter != isCenter)
        {
            m_IsCenter = isCenter;
            if (m_CoverFlow != null && m_CoverFlow.IsStarted)
            {
                if (OnValueChanged != null)
                {
                    OnValueChanged(isCenter);
                }
            }
        }
    }

    /// <summary>
    /// 响应选中元素
    /// </summary>
    protected virtual void OnItemClicked()
    {
        if (m_IsCenter)
        {
            if (CenterItemOnClicked != null)
            {
                CenterItemOnClicked();
            }
        }
        if (m_CoverFlow != null)
        {
            m_CoverFlow.SetHorizontalTargetItemIndex(this);
        }
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        if (m_PointerId == int.MinValue)
        {
            m_LocalPointOfPointerDown = transform.localPosition;
            m_PointerId = eventData.pointerId;
            m_IsResponseClick = true;
        }
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        if (eventData.pointerId == m_PointerId)
        {
            // 点击的区域未移动，才响应点击，点击的时候元素是静止的，避免点击到滑动过程中的元素，响应移动
            if (m_IsResponseClick && eventData.position == eventData.pressPosition && m_LocalPointOfPointerDown == transform.localPosition)
            {
                OnItemClicked();
            }
            m_PointerId = int.MinValue;
            m_IsResponseClick = true;
        }
    }

    public void OnBeginDrag(PointerEventData eventData)
    {

    }

    public void OnEndDrag(PointerEventData eventData)
    {
        if (m_CoverFlow != null)
        {
            m_CoverFlow.OnDragEnhanceViewEnd();
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (eventData.pointerId == m_PointerId)
        {
            m_IsResponseClick = false;
        }

        if (m_CoverFlow != null)
        {
            m_CoverFlow.OnDragEnhanceViewMove(eventData.delta);
        }
    }

}