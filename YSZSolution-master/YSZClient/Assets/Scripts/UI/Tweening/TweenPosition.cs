
using UnityEngine;
using System.Collections;

/// <summary>
/// Tween the object's position.
/// </summary>
public class TweenPosition : UITweener
{
    /// <summary>
    /// 初始位置
    /// </summary>
    public Vector3 from;
    /// <summary>
    /// 目标位置
    /// </summary>
    public Vector3 to;

    /// <summary>
    /// 世界坐标系
    /// </summary>
    [HideInInspector]
    public bool worldSpace = false;

    /// <summary>
    /// 组件
    /// </summary>
    Transform mTrans;

    /// <summary>
    /// 获取组件接口
    /// </summary>
    public Transform cachedTransform
    {
        get
        {
            if (mTrans == null)
                mTrans = transform;
            return mTrans;
        }
    }

    /// <summary>
    /// Tween's current value.
    /// </summary>
    public Vector3 value
    {
        get
        {
            return worldSpace ? cachedTransform.position : cachedTransform.localPosition;
        }
        set
        {
            if (worldSpace)
                cachedTransform.position = value;
            else
                cachedTransform.localPosition = value;
        }
    }

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

    static public TweenPosition Begin(GameObject target, float duration, Vector3 pos)
    {
        TweenPosition tweenComp = UITweener.Begin<TweenPosition>(target, duration);
        tweenComp.from = tweenComp.value;
        tweenComp.to = pos;
        if (duration <= 0f)
        {
            tweenComp.Sample(1f, true);
            tweenComp.enabled = false;
        }
        return tweenComp;
    }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>
    static public TweenPosition Begin(GameObject target, float duration, Vector3 pos, bool worldSpace)
    {
        TweenPosition tweenComp = UITweener.Begin<TweenPosition>(target, duration);
        tweenComp.worldSpace = worldSpace;
        tweenComp.from = tweenComp.value;
        tweenComp.to = pos;

        if (duration <= 0f)
        {
            tweenComp.Sample(1f, true);
            tweenComp.enabled = false;
        }
        return tweenComp;
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
