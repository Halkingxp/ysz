using System;
using UnityEngine;

/// <summary>
/// 选择控制
/// </summary>
public class RotationChangeScript : MonoBehaviour
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
    /// 开始角度
    /// </summary>
    Vector3 mBeginEuler;
    /// <summary>
    /// 是否旋转
    /// </summary>
    bool isRotation = false;
    /// <summary>
    /// 控制组件
    /// </summary>
    RectTransform mRect;
    /// <summary>
    /// 结束通知事件
    /// </summary>
    Action mFunc;
    /// <summary>
    /// 选择角度delta
    /// </summary>
    Vector3 mRotationDelta;

    /// <summary>
    /// 开始旋转
    /// </summary>
    /// <param name="endEuler"></param>
    /// <param name="time"></param>
    /// <param name="func"></param>
    public void StartRotation(Vector3 endEuler, float time, Action func = null)
    {
        //print("rotation 11111111111111111111111");
        if (mRect == null)
        {
            mRect = this.GetComponent<RectTransform>();
        }
        mBeginEuler = mRect.eulerAngles;
        mTime = time;
        mFunc = func;
        mTimeCount = 0;
        mRotationDelta = Vector3.zero;
        mRotationDelta.x = (mRect.eulerAngles.x - endEuler.x);
        mRotationDelta.y = (mRect.eulerAngles.y - endEuler.y);
        mRotationDelta.z = (mRect.eulerAngles.z - endEuler.z);
        isRotation = true;
    }

    // Update is called once per frame
    void Update()
    {
        if (isRotation == true)
        {
            //print("rotation 2222222222222222222");
            mTimeCount += Time.deltaTime;
            mRect.eulerAngles = mBeginEuler - mRotationDelta * (mTimeCount / mTime);
            if (mTimeCount >= mTime)
            {
                //print("rotation 333333333333333333333");
                isRotation = false;
                if (mFunc != null)
                {
                    mFunc.Invoke();
                }
            }
        }
    }

    private void OnDisable()
    {
        isRotation = false;
        if (mRect)
        {
            mRect.eulerAngles = mBeginEuler;
        }
    }

}
