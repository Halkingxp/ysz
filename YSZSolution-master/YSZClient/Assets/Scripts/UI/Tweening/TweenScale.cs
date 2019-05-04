//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************

using UnityEngine;
using System.Collections;

/// <summary>
/// Tween the object's Scale.
/// </summary>
public class TweenScale : UITweener
{
    /// <summary>
    /// 初始缩放比例
    /// </summary>
    public Vector3 from = Vector3.one;
    /// <summary>
    /// 目标缩放比例
    /// </summary>
    public Vector3 to = Vector3.one;

    /// <summary>
    /// 缓存组件
    /// </summary>
    Transform mTrans;

    /// <summary>
    /// 获取缓存组件接口
    /// </summary>
    public Transform cachedTransform { get { if (mTrans == null) mTrans = transform; return mTrans; } }

    public Vector3 value { get { return cachedTransform.localScale; } set { cachedTransform.localScale = value; } }


    /// <summary>
    /// Tween the value.
    /// </summary>
    protected override void OnUpdate(float factor, bool isFinished)
    {
        value = from * (1f - factor) + to * factor;        
    }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>

    static public TweenScale Begin(GameObject go, float duration, Vector3 scale)
    {
        TweenScale comp = UITweener.Begin<TweenScale>(go, duration);
        comp.from = comp.value;
        comp.to = scale;

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