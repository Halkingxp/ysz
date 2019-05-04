using UnityEngine;
using System;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.Serialization;


/// <summary> 
/// Pressed按钮
/// 脚本位置：UGUI按钮组件身上  
/// 脚本功能：实现按钮长按状态的判断  
/// </summary>  
// 继承：按下，抬起和离开的三个接口  

[XLua.LuaCallCSharp]
public class OnButtonPressed : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler
{
    /// <summary>
    /// 按钮长按事件
    /// </summary>
    [Serializable]
    public class ButtonLongPressedEvent : UnityEvent { }

    /// <summary>
    /// Event delegates triggered on click.
    /// </summary>
    [FormerlySerializedAs("onLongPressed")]
    [SerializeField]
    private ButtonLongPressedEvent m_OnLongPressed = new ButtonLongPressedEvent();
    /// <summary>
    /// 长按事件
    /// </summary>
    public ButtonLongPressedEvent onLongPressed
    {
        get { return m_OnLongPressed; }
        set { m_OnLongPressed = value; }
    }

    [Serializable]
    public class ButtonPressedEvent : UnityEvent<bool> { }

    [FormerlySerializedAs("onPressed")]
    [SerializeField]
    private ButtonPressedEvent m_OnPressed = new ButtonPressedEvent();
    /// <summary>
    /// 按下事件
    /// </summary>
    public ButtonPressedEvent onPressed
    {
        get { return m_OnPressed; }
        set { m_OnPressed = value; }
    }


    /// <summary>
    /// 延迟时间
    /// </summary>
    public float delay = 0.2f;

    /// <summary>
    /// 按钮是否是按下状态  
    /// </summary>
    private bool isDown = false;

    /// <summary>
    /// 按钮最后一次是被按住状态时候的时间  
    /// </summary>
    private float lastIsDownTime;

    /// <summary>
    /// 按钮按下
    /// 当按钮被按下后系统自动调用此方法  
    /// </summary>
    /// <param name="eventData"></param>
    public void OnPointerDown(PointerEventData eventData)
    {
        isDown = true;
        lastIsDownTime = Time.time;
        m_OnPressed.Invoke(true);
    }

    /// <summary>
    /// 按钮抬起
    /// 当按钮抬起的时候自动调用此方法  
    /// </summary>
    /// <param name="eventData"></param>
    public void OnPointerUp(PointerEventData eventData)
    {
        isDown = false;
        m_OnPressed.Invoke(false);
    }

    /// <summary>
    /// 当鼠标从按钮上离开的时候自动调用此方法
    /// </summary>
    /// <param name="eventData"></param>
    public void OnPointerExit(PointerEventData eventData)
    {
        isDown = false;
        m_OnPressed.Invoke(false);
    }

    void Update()
    {
        // 如果按钮是被按下状态  
        if (isDown)
        {
            // 当前时间 -  按钮最后一次被按下的时间 > 延迟时间0.2秒  
            if (Time.time - lastIsDownTime > delay)
            {
                // 触发长按方法  
                m_OnLongPressed.Invoke();
                // 记录按钮最后一次被按下的时间  
            }
        }

    }

}