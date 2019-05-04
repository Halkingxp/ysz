using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

/// <summary>
/// 浏览模式
/// </summary>
public enum FlipMode : int
{
    /// <summary>
    /// 无
    /// </summary>
    None = 0,
    /// <summary>
    /// 左侧开始
    /// </summary>
    Left = 1,

    /// <summary>
    /// 中间开始
    /// </summary>
    Middle = 2,
}

/// <summary>
/// 搓牌控制脚本
/// </summary>
[XLua.LuaCallCSharp]
public class PageCurl : MonoBehaviour, IBeginDragHandler, IEndDragHandler, IDragHandler
{
    /// <summary>
    /// 页签的根结点
    /// </summary>
    [SerializeField]
    RectTransform m_PagePlane = null;

    /// <summary>
    /// 裁剪平面
    /// </summary>
    [SerializeField]
    RectTransform m_ClippingPlane = null;

    /// <summary>
    /// 页1
    /// </summary>
    [SerializeField]
    RectTransform m_PageOne = null;

    /// <summary>
    /// 页2
    /// </summary>
    [SerializeField]
    RectTransform m_PageTwo = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    RectTransform m_Shadow = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    RectTransform m_RotateFlag1 = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    RectTransform m_RotateFlag2 = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    Image m_PageOneSprite = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    Image m_PageTwoSprite = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    GameObject m_ClipModeGo = null;
    /// <summary>
    /// 
    /// </summary>
    [SerializeField]
    Button m_RotateButton = null;
    /// <summary>
    /// 
    /// </summary>
    Vector3 spineBottom;
    /// <summary>
    /// 
    /// </summary>
    Vector3 edgeLeftBottom;

    bool isStarted = false;

    const float m_MinDistance = 0.01f;

    float m_Radius = 100f;

    public FlipMode FlipMode
    {
        get; private set;
    }

    /// <summary>
    /// for lua
    /// </summary>
    public int FlipModeValue
    {
        get { return (int)this.FlipMode; }
    }

    [SerializeField]
    bool isSpriteRotate = false;
    public bool IsSpriteRotated
    {
        get { return isSpriteRotate; }
        private set { isSpriteRotate = value; }
    }

    /// <summary>
    /// 当前拐角点
    /// </summary>
    public Vector3 MoveSpace;

    bool interactable = true;

    /// <summary>
    /// 是否已经开启状态
    /// </summary>
    public bool IsOpened { get; private set; }

    public bool CanHandle { get; private set; }

    private string m_Sprite2Name = string.Empty;

    public void ResetSprites(string sprite1Name, string sprite2Name)
    {
        m_PageOneSprite.ResetSpriteByName(sprite1Name);
        m_PageTwoSprite.ResetSpriteByName(sprite2Name);
        m_Sprite2Name = sprite2Name;
    }

    public void ResetPageCurl(float pageWidth, float pageHeight, bool spriteRotate = false, bool canHandle = false)
    {
        FlipMode = FlipMode.Middle;
        this.MoveSpace = new Vector3(0, m_MinDistance, 0);
        float max = Mathf.Max(pageHeight, pageWidth);
        m_Radius = Mathf.Sqrt(pageWidth * pageWidth + pageHeight * pageHeight) / 2;

        Vector2 planeSize = new Vector2(pageWidth, pageHeight);

        m_PagePlane.sizeDelta = planeSize;
        // 重置定位点坐标
        spineBottom = new Vector3(0, -pageHeight / 2, 0);
        edgeLeftBottom = new Vector3(-pageWidth / 2, -pageHeight / 2);

        ResetRectTransform(m_ClippingPlane, m_PagePlane, true, new Vector2(max * 2, max * 3));
        ResetRectTransform(m_PageOne, m_PagePlane, true, planeSize);
        ResetRectTransform(m_PageTwo, m_PagePlane, true, planeSize);
        ResetRectTransform(m_Shadow, m_PageTwo, true, new Vector2(pageWidth, max * 3));

        isStarted = false;
        interactable = false;
        IsOpened = false;
        CanHandle = canHandle;
        this.IsSpriteRotated = spriteRotate;
        lastDragSpace = Vector3.zero;
        Vector2 pivot = new Vector2(0.5f, 0.5f);
        Vector2 size = spriteRotate ? new Vector2(pageHeight, pageWidth) : new Vector2(pageWidth, pageHeight);
        Vector3 angle = spriteRotate ? new Vector3(0, 0, -90) : Vector3.zero;
        SetRectTransform(m_PageOneSprite.rectTransform, m_PagePlane, true, size, pivot, Vector3.zero, angle);
        SetRectTransform(m_PageTwoSprite.rectTransform, m_PagePlane, true, size, pivot, Vector3.zero, angle);

        m_PageOneSprite.transform.SetParent(m_PageOne, true);
        m_PageTwoSprite.transform.SetParent(m_PageTwo, true);
        m_ClipModeGo.SetActive(canHandle);
        m_RotateButton.gameObject.SetActive(canHandle);
        RefreshDirectionFlagByRotate(pageWidth);
        UpdatePage(this.MoveSpace, this.FlipMode);
    }
    /// <summary>
    /// 重置
    /// </summary>
    /// <param name="trans"></param>
    /// <param name="baseTrans"></param>
    /// <param name="active"></param>
    /// <param name="size"></param>
    void ResetRectTransform(RectTransform trans, RectTransform baseTrans, bool active, Vector2 size)
    {
        SetRectTransform(trans, baseTrans, active, size, new Vector2(0.5f, 0.5f), Vector3.zero, Vector3.zero);
    }

    /// <summary>
    /// 设置data
    /// </summary>
    /// <param name="trans"></param>
    /// <param name="baseTrans"></param>
    /// <param name="active"></param>
    /// <param name="size"></param>
    /// <param name="pivot"></param>
    /// <param name="localPoint"></param>
    /// <param name="angle"></param>
    void SetRectTransform(RectTransform trans, RectTransform baseTrans, bool active, Vector2 size, Vector2 pivot, Vector3 localPoint, Vector3 angle)
    {
        trans.SetParent(baseTrans, true);
        trans.gameObject.SetActive(active);
        trans.sizeDelta = size;
        trans.pivot = pivot;
        trans.localPosition = localPoint;
        trans.localEulerAngles = angle;
    }

    /// <summary>
    /// 选择页面上的按钮
    /// </summary>
    void RotateButton_OnClick()
    {
        RotatePage();
        NotifyPageChanged();
    }
    /// <summary>
    /// 选择页面
    /// </summary>
    public void RotatePage()
    {
        IsSpriteRotated = !IsSpriteRotated;
        RefreshDirectionFlagByRotate(m_PagePlane.sizeDelta.y);
        ResetPageCurl(m_PagePlane.sizeDelta.y, m_PagePlane.sizeDelta.x, IsSpriteRotated, CanHandle);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="width"></param>
    public void RefreshDirectionFlagByRotate(float width)
    {
        m_RotateFlag1.gameObject.SetActive(IsSpriteRotated);
        m_RotateFlag2.gameObject.SetActive(!IsSpriteRotated);
    }

    Vector3 m_StartDragLocalPoint = Vector3.zero;

    /// <summary>
    /// 拖拽开始
    /// </summary>
    /// <param name="eventData"></param>
    public void OnBeginDrag(PointerEventData eventData)
    {
        if (IsOpened || !CanHandle)
            return;
        m_StartDragLocalPoint = ScreenToLocal(eventData) - lastDragSpace;
        if (isStarted)
        {
            interactable = true;
            return;
        }

        if (RectTransformUtility.RectangleContainsScreenPoint(m_PagePlane, eventData.position, eventData.pressEventCamera))
        {
            isStarted = true;
            m_LastMoveSpace = MoveSpace;
            m_LastUpdateTime = Time.realtimeSinceStartup;
        }
        else
        {
            isStarted = false;
        }
    }

    /// <summary>
    /// 拖拽结束
    /// </summary>
    /// <param name="eventData"></param>
    public void OnEndDrag(PointerEventData eventData)
    {
        if (CanHandle)
        {
            if (!interactable)
            {
                isStarted = false;
            }
            interactable = false;
        }
    }

    Vector3 m_LastMoveSpace;
    float m_LastUpdateTime;

    float m_NofityInterval = 0.2f;

    /// <summary>
    /// 刷新浏览
    /// </summary>
    /// <param name="movedSpace"></param>
    void RefreshFlipMode(Vector2 movedSpace)
    {
        if (movedSpace.magnitude > 10f)// 最小滑动10个像素才开始启动
        {
            float angle = CalcVector2Angle(movedSpace);
            if (angle < 40 || angle > 320)// 响应左下角点
            {
                interactable = true;
                FlipMode = FlipMode.Left;
            }
            else if (angle >= 40 && angle < 145)
            {
                interactable = true;
                FlipMode = FlipMode.Middle;
            }

            if (interactable)
            {
                m_ClipModeGo.SetActive(false);
                m_RotateButton.gameObject.SetActive(false);
            }
        }
    }

    Vector3 lastDragSpace = Vector3.zero;
    /// <summary>
    /// 拖拽中
    /// </summary>
    /// <param name="eventData"></param>
    public void OnDrag(PointerEventData eventData)
    {
        Vector3 m_CurrentDragPoint = ScreenToLocal(eventData);
        if (isStarted && CanHandle && !IsOpened && !interactable)
        {
            RefreshFlipMode(m_CurrentDragPoint - m_StartDragLocalPoint);
        }

        if (CanHandle && interactable && !IsOpened)
        {
            lastDragSpace = m_CurrentDragPoint - m_StartDragLocalPoint;
            switch (this.FlipMode)
            {
                case FlipMode.Left:
                    InternalUpdateLeftMode(edgeLeftBottom + lastDragSpace);
                    break;
                case FlipMode.Middle:
                default:
                    InternalUpdateMiddlePoint(spineBottom + lastDragSpace);
                    break;
            }

            if ((m_LastMoveSpace - MoveSpace).magnitude > 5 && (Time.realtimeSinceStartup - m_LastUpdateTime) > m_NofityInterval)
            {
                NotifyPageChanged();
            }
        }
    }

    /// <summary>
    /// 初始化中心点
    /// </summary>
    /// <param name="followPoint"></param>
    void InternalUpdateMiddlePoint(Vector3 followPoint)
    {
        const float angleMinLimit = 80;
        const float angleMaxLimit = 100;
        Vector3 moveSpace = followPoint - spineBottom;
        float angle = CalcVector2Angle(moveSpace);

        if (angle < angleMinLimit || angle > angleMaxLimit)
        {
            if (moveSpace.x > 0)
            {
                if (moveSpace.y > 0)
                {
                    moveSpace.x = moveSpace.y / Mathf.Tan(angleMinLimit * Mathf.Deg2Rad);
                }
                else
                {
                    moveSpace = Vector2.up * m_MinDistance;
                }
            }
            else if (moveSpace.x < 0)
            {
                if (moveSpace.y > 0)
                {
                    moveSpace.x = moveSpace.y / Mathf.Tan(angleMaxLimit * Mathf.Deg2Rad);
                }
                else
                {
                    moveSpace = Vector2.up * m_MinDistance;
                }
            }
            else
            {
                moveSpace = Vector2.up * m_MinDistance;
            }
        }
        this.UpdatePage(moveSpace, FlipMode.Middle);
        CaclVisibleRange();
    }

    /// <summary>
    /// 初始化Left点
    /// </summary>
    /// <param name="followPoint"></param>
    void InternalUpdateLeftMode(Vector3 followPoint)
    {
        const float angleMinLimit = 1;
        const float angleMaxLimit = 100;
        Vector3 moveSpace = followPoint - edgeLeftBottom;
        float angle = CalcVector2Angle(moveSpace);
        if (angle < angleMinLimit || angle > angleMaxLimit)
        {
            if (moveSpace.x > 0)
            {
                moveSpace.y = Mathf.Tan(angleMinLimit * Mathf.Deg2Rad) * moveSpace.x;
            }
            else if (moveSpace.x < 0)
            {
                if (moveSpace.y > 0)
                {
                    moveSpace.x = moveSpace.y / Mathf.Tan(angleMaxLimit * Mathf.Deg2Rad);
                }
                else
                {
                    moveSpace = Vector2.right * m_MinDistance;
                }
            }
            else
            {
                moveSpace = Vector2.right * m_MinDistance;
            }
        }

        this.UpdatePage(moveSpace, FlipMode.Left);
        CaclVisibleRange();
    }

    #region 更新不同的模式

    /// <summary>
    /// 更新页面
    /// </summary>
    /// <param name="moveSpace"></param>
    /// <param name="mode"></param>
    public void UpdatePage(Vector3 moveSpace, FlipMode mode)
    {
        this.MoveSpace = moveSpace;
        this.FlipMode = mode;
        if (IsOpened)
            return;
        switch (mode)
        {
            case FlipMode.Left:
                UpdateLeftMode(moveSpace);
                break;
            case FlipMode.Middle:
            default:
                UpdateMiddleMode(moveSpace);
                break;
        }
    }

    /// <summary>
    /// 更新坐标点，起始点
    /// </summary>
    /// <param name="moveSpace"></param>
    void UpdateMiddleMode(Vector3 moveSpace)
    {
        float angle = CalcVector2Angle(moveSpace);
        Vector3 clipingPlanePoint = spineBottom + moveSpace / 2;
        m_PageOne.SetParent(m_PagePlane, true);
        m_PageTwo.SetParent(m_PagePlane, true);
        m_Shadow.SetParent(m_ClippingPlane, true);

        m_Shadow.pivot = new Vector2(0, 0.5f);
        m_ClippingPlane.pivot = new Vector2(0, 0.5f);

        m_Shadow.localEulerAngles = new Vector3(0, 0, 0);
        m_Shadow.localPosition = new Vector3(0, 0, 0);

        m_ClippingPlane.eulerAngles = new Vector3(0, 0, angle);
        m_ClippingPlane.position = m_PagePlane.TransformPoint(clipingPlanePoint);

        m_PageTwo.pivot = new Vector2(0.5f, 0f);
        m_PageTwo.position = m_PagePlane.TransformPoint(spineBottom + moveSpace);
        m_PageTwo.eulerAngles = new Vector3(0, 0, angle * 2);

        m_PageTwo.SetParent(m_ClippingPlane, true);
        m_PageOne.SetParent(m_ClippingPlane, true);
        m_PageOne.SetAsFirstSibling();
        m_Shadow.SetParent(m_PageTwo, true);
    }

    /// <summary>
    /// 更新左侧点为起点模式
    /// </summary>
    /// <param name="moveSpace"></param>
    void UpdateLeftMode(Vector3 moveSpace)
    {
        float angle = CalcVector2Angle(moveSpace);
        Vector3 clipingPlanePoint = edgeLeftBottom + moveSpace / 2;
        m_PageOne.SetParent(m_PagePlane, true);
        m_PageTwo.SetParent(m_PagePlane, true);
        m_Shadow.SetParent(m_ClippingPlane, true);
        if (angle < 90)
        {
            m_ClippingPlane.pivot = new Vector2(0, 0.35f);
            m_Shadow.pivot = new Vector2(0, 0.35f);
        }
        else
        {
            m_ClippingPlane.pivot = new Vector2(0, 0.65f);
            m_Shadow.pivot = new Vector2(0, 0.65f);
        }

        m_Shadow.localEulerAngles = new Vector3(0, 0, 0);
        m_Shadow.localPosition = new Vector3(0, 0, 0);

        m_ClippingPlane.eulerAngles = new Vector3(0, 0, angle);
        m_ClippingPlane.position = m_PagePlane.TransformPoint(clipingPlanePoint);

        m_PageTwo.pivot = new Vector2(1f, 0f);
        m_PageTwo.position = m_PagePlane.TransformPoint(edgeLeftBottom + moveSpace);
        m_PageTwo.eulerAngles = new Vector3(0, 0, angle * 2);

        m_PageTwo.SetParent(m_ClippingPlane, true);
        m_PageOne.SetParent(m_ClippingPlane, true);
        m_PageOne.SetAsFirstSibling();
        m_Shadow.SetParent(m_PageTwo, true);
    }

    #endregion

    /// <summary>
    /// 屏幕坐标到本地坐标
    /// </summary>
    /// <param name="eventData"></param>
    /// <returns></returns>
    public Vector3 ScreenToLocal(PointerEventData eventData)
    {
        Vector2 local;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(m_PagePlane, eventData.position, eventData.pressEventCamera, out local);
        return local;
    }

    /// <summary>
    /// 计算向量的角度 与 (1,0)向量的夹角
    /// </summary>
    /// <param name="v">向量</param>
    /// <returns>返回 [0,360)</returns>
    float CalcVector2Angle(Vector2 v)
    {
        float angle = Mathf.Atan2(v.y, v.x) * Mathf.Rad2Deg;
        return (angle + 360) % 360;
    }

    /// <summary>
    /// 开牌回调
    /// </summary>
    public event Action<object> OpenCardCallBack;

    /// <summary>
    /// 通知界面打开了
    /// </summary>
    public void OpenCard()
    {
        if (IsOpened)
            return;
        IsOpened = true;
        m_PageOneSprite.ResetSpriteByName(m_Sprite2Name);
        m_PageOne.SetParent(m_PagePlane, true);
        m_PageTwo.SetParent(m_PagePlane, true);
        m_PageTwo.gameObject.SetActive(false);
        m_ClippingPlane.gameObject.SetActive(false);
        m_ClipModeGo.SetActive(false);
        m_RotateButton.gameObject.SetActive(false);
    }

    /// <summary>
    /// 通知页面打开事件
    /// </summary>
    void NotifyOpenCard()
    {
        IsOpened = true;
        m_PageOneSprite.sprite = m_PageTwoSprite.sprite;
        m_PageOne.SetParent(m_PagePlane, true);
        m_PageTwo.SetParent(m_PagePlane, true);
        m_PageTwo.gameObject.SetActive(false);
        m_ClippingPlane.gameObject.SetActive(false);
        m_ClipModeGo.SetActive(false);
        m_RotateButton.gameObject.SetActive(false);
        if (OpenCardCallBack != null)
        {
            OpenCardCallBack(UserData);
        }
    }

    /// <summary>
    /// 可见区域裁决
    /// </summary>
    void CaclVisibleRange()
    {
        if (MoveSpace.magnitude > m_Radius * 1.2f)
        {
            NotifyOpenCard();
            return;
        }
    }

    /// <summary>
    /// 用户数据
    /// </summary>
    public object UserData { get; set; }

    /// <summary>
    /// 页面改变事件
    /// </summary>
    public event Action<object> PageChangedEvent;

    /// <summary>
    /// 通知页面改变事件
    /// </summary>
    void NotifyPageChanged()
    {
        if (PageChangedEvent != null)
        {
            PageChangedEvent(UserData);
        }
    }

    private void Awake()
    {
        IsSpriteRotated = true;
        IsOpened = false;
        ResetPageCurl(m_PagePlane.sizeDelta.x, m_PagePlane.sizeDelta.y, false);
        m_RotateButton.onClick.AddListener(RotateButton_OnClick);
    }

}