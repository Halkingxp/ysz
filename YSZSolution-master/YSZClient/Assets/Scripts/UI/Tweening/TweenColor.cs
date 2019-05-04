
using UnityEngine.UI;
using UnityEngine;

/// <summary>
/// Tween the object's color.
/// </summary>
public class TweenColor : UITweener
{
    /// <summary>
    /// 初始颜色值
    /// </summary>
    public Color from = Color.white;
    /// <summary>
    /// 目标颜色值
    /// </summary>
    public Color to = Color.white;

    /// <summary>
    /// 换成tag
    /// </summary>
    bool mCached = false;
    /// <summary>
    /// UI image
    /// </summary>
    Image image;
    /// <summary>
    /// 材质
    /// </summary>
    Material mMat;
    /// <summary>
    /// 光照数据
    /// </summary>
    Light mLight;
    /// <summary>
    /// 精灵渲染组件
    /// </summary>
    SpriteRenderer mSr;

    /// <summary>
    /// 缓存组件方法
    /// </summary>
    void Cache()
    {
        mCached = true;
        image = GetComponent<Image>();
        if (image != null)
            return;
        mSr = GetComponent<SpriteRenderer>();
        if (mSr != null)
            return;
        Renderer ren = GetComponent<Renderer>();
        if (ren != null)
        {
            mMat = ren.material;
            return;
        }
        mLight = GetComponent<Light>();

    }

    /// <summary>
    /// Tween's current value.
    /// </summary>
    public Color value
    {
        get
        {
            if (!mCached) Cache();
            if (image != null) return image.color;
            if (mMat != null) return mMat.color;
            if (mSr != null) return mSr.color;
            if (mLight != null) return mLight.color;
            return Color.black;
        }
        set
        {
            if (!mCached) Cache();
            if (image != null) image.color = value;
            else if (mMat != null) mMat.color = value;
            else if (mSr != null) mSr.color = value;
            else if (mLight != null)
            {
                mLight.color = value;
                mLight.enabled = (value.r + value.g + value.b) > 0.01f;
            }
        }
    }

    /// <summary>
    /// Tween the value.
    /// </summary>

    protected override void OnUpdate(float factor, bool isFinished)
    {
        value = Color.Lerp(from, to, factor);
    }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>

    static public TweenColor Begin(GameObject go, float duration, Color color)
    {
#if UNITY_EDITOR
        if (!Application.isPlaying) return null;
#endif
        TweenColor comp = UITweener.Begin<TweenColor>(go, duration);
        comp.from = comp.value;
        comp.to = color;
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