
//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************
using UnityEngine;
using System.Collections;

/// <summary>
/// Tween the object's Rotation.
/// </summary>
public class TweenRotation : UITweener
{
    /// <summary>
    /// 初始旋转值
    /// </summary>
    public Vector3 from;
    /// <summary>
    /// 目标旋转值
    /// </summary>
    public Vector3 to;

    /// <summary>
    /// 是否进行四元数插值
    /// </summary>
    public bool quaternionLerp = false;
    /// <summary>
    /// 组件
    /// </summary>
    Transform mTrans;

    /// <summary>
    /// 获取缓存组件接口
    /// </summary>
    public Transform cachedTransform
    {
        get
        {
            if (mTrans == null)
            {
                mTrans = transform;
            }
            return mTrans;
        }
    }

    /// <summary>
    /// Tween's current value.
    /// </summary>

    public Quaternion value
    {
        get
        {
            return cachedTransform.localRotation;
        }
        set
        {
            cachedTransform.localRotation = value;
        }
    }

    /// <summary>
    /// Tween the value.
    /// </summary>
    protected override void OnUpdate(float factor, bool isFinished)
    {
        value = quaternionLerp
            ? Quaternion.Slerp(Quaternion.Euler(from), Quaternion.Euler(to), factor)
            : Quaternion.Euler(new Vector3(Mathf.Lerp(from.x, to.x, factor), Mathf.Lerp(from.y, to.y, factor), Mathf.Lerp(from.z, to.z, factor)));
    }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>
    static public TweenRotation Begin(GameObject go, float duration, Quaternion rot)
    {
        TweenRotation comp = UITweener.Begin<TweenRotation>(go, duration);
        comp.from = comp.value.eulerAngles;
        comp.to = rot.eulerAngles;

        if (duration <= 0f)
        {
            comp.Sample(1f, true);
            comp.enabled = false;
        }
        return comp;
    }
    [ContextMenu("Set 'From' to current value")]
    public override void SetStartToCurrentValue() { from = value.eulerAngles; }

    [ContextMenu("Set 'To' to current value")]
    public override void SetEndToCurrentValue() { to = value.eulerAngles; }

    [ContextMenu("Assume value of 'From'")]
    void SetCurrentValueToStart() { value = Quaternion.Euler(from); }

    [ContextMenu("Assume value of 'To'")]
    void SetCurrentValueToEnd() { value = Quaternion.Euler(to); }


}
