//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************

using UnityEngine;
using System.Collections;

/// <summary>
/// 宽度变化
/// </summary>
[RequireComponent(typeof(RectTransform))]
public class TweenWidth : UITweener
{
    /// <summary>
    /// 初始值
    /// </summary>
    public float from = 100;
    /// <summary>
    /// 目标值
    /// </summary>
    public float to = 100;
    /// <summary>
    /// 组件
    /// </summary>
    RectTransform mWidget;


    public RectTransform cachedWidget { get { if (mWidget == null) mWidget = GetComponent<RectTransform>(); return mWidget; } }


    /// <summary>
    /// Tween's current value.
    /// </summary>

    public float value { get { return cachedWidget.rect.width; } set { cachedWidget.sizeDelta = new Vector2(value, cachedWidget.rect.height); } }

    /// <summary>
    /// Tween the value.
    /// </summary>

    protected override void OnUpdate(float factor, bool isFinished)
    {
        value = Mathf.RoundToInt(from * (1f - factor) + to * factor);
    }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>

    static public TweenWidth Begin(RectTransform widget, float duration, int width)
    {
        TweenWidth comp = UITweener.Begin<TweenWidth>(widget.gameObject, duration);
        comp.from = widget.sizeDelta.x;
        comp.to = width;

        if (duration <= 0f)
        {
            comp.Sample(1f, true);
            comp.enabled = false;
        }
        return comp;
    }

    [ContextMenu("Set 'From' to current value")]
    public override void SetStartToCurrentValue() { from = value; }

    [ContextMenu("Set 'To' to current value")]
    public override void SetEndToCurrentValue() { to = value; }

    [ContextMenu("Assume value of 'From'")]
    void SetCurrentValueToStart() { value = from; }

    [ContextMenu("Assume value of 'To'")]
    void SetCurrentValueToEnd() { value = to; }


}

