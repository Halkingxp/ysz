using UnityEngine;
using System;

/// <summary>
/// 缩放控制脚本
/// </summary>
public class ScaleChangeScript : MonoBehaviour
{
    /// <summary>
    /// 持续时间
    /// </summary>
    float mTime;
    /// <summary>
    /// CD计时
    /// </summary>
    float mTimeCount;
    /// <summary>
    /// 最终缩放
    /// </summary>
    float mScaleEnd;
    /// <summary>
    /// 当前缩放
    /// </summary>
    float mCurrentScale;
    /// <summary>
    /// 开始缩放
    /// </summary>
    float mScaleBegin;
    /// <summary>
    /// 缩放速度
    /// </summary>
    float mScaleSpeed;
    /// <summary>
    /// 回调方法
    /// </summary>
    Action m_func;
    /// <summary>
    /// 缩放开始tag
    /// </summary>
    bool isScaling = false;
    /// <summary>
    /// 组件
    /// </summary>
    RectTransform mRectTransform;
    // Update is called once per frame
    void Update()
    {
        if (isScaling == true)
        {
            mTimeCount += Time.deltaTime;
            mCurrentScale = mCurrentScale - mScaleSpeed * Time.deltaTime;
            mRectTransform.localScale = new Vector3(mCurrentScale, mCurrentScale, mCurrentScale);
            if (mTimeCount >= mTime)
            {
                isScaling = false;
                if (m_func != null)
                {
                    m_func.Invoke();
                }
            }
        }
    }

    private void OnDisable()
    {
        isScaling = false;
    }

    /// <summary>
    /// 开始缩放
    /// </summary>
    /// <param name="scaleEnd"></param>
    /// <param name="time"></param>
    /// <param name="func"></param>
    public void StartScale(float scaleEnd, float time, Action func = null)
    {
        if (mRectTransform == null)
        {
            mRectTransform = this.GetComponent<RectTransform>();
        }
        if (scaleEnd == mRectTransform.localScale.x)
        {
            return;
        }
        mScaleEnd = scaleEnd;
        mTime = time;
        m_func = func;
        isScaling = true;
        mScaleBegin = mRectTransform.localScale.x;
        mTimeCount = 0;
        mScaleSpeed = (mScaleBegin - mScaleEnd) / time;
        mCurrentScale = mScaleBegin;
    }

}
