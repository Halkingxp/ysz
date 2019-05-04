
using UnityEngine.UI;
using UnityEngine;


/// <summary>
/// Alpha 渐进控制
/// </summary>
public class TweenAlpha : UITweener
{
    /// <summary>
    /// 初始值
    /// </summary>
    [Range(0f, 1f)]
    public float from = 1f;
    /// <summary>
    /// 目标值
    /// </summary>
    [Range(0f, 1f)]
    public float to = 1f;

    bool mCached = false;
    Image image;
    Material mMat;
    SpriteRenderer mSr;
    Text mText;

    /// <summary>
    /// 组件缓存
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
        image = GetComponentInChildren<Image>();

        mText = GetComponent<Text>();
        if (mText != null)
            return;
    }

    /// <summary>
    /// Tween's current value.
    /// </summary>

    public float value
    {
        get
        {
            if (!mCached) Cache();
            if (image != null)
                return image.color.a;
            if (mSr != null) return mSr.color.a;
            if (mText != null)
            {
                return mText.color.a;
            }
            return mMat != null ? mMat.color.a : 1f;


        }
        set
        {
            if (!mCached)
                Cache();
            else if (image != null)
            {
                Color c = image.color;
                c.a = value;
                image.color = c;
            }
            else if (mSr != null)
            {
                Color c = mSr.color;
                c.a = value;
                mSr.color = c;
            }
            else if (mText != null)
            {
                Color c = mText.color;
                c.a = value;
                mText.color = c;
            }
            else if (mMat != null)
            {
                Color c = mMat.color;
                c.a = value;
                mMat.color = c;
            }
        }
    }

    /// <summary>
    /// Tween the value.
    /// </summary>

    protected override void OnUpdate(float factor, bool isFinished) { value = Mathf.Lerp(from, to, factor); }

    /// <summary>
    /// Start the tweening operation.
    /// </summary>

    static public TweenAlpha Begin(GameObject go, float duration, float alpha)
    {
        TweenAlpha comp = UITweener.Begin<TweenAlpha>(go, duration);
        comp.from = comp.value;
        comp.to = alpha;

        if (duration <= 0f)
        {
            comp.Sample(1f, true);
            comp.enabled = false;
        }
        return comp;
    }

    public override void SetStartToCurrentValue() { from = value; }
    public override void SetEndToCurrentValue() { to = value; }


}