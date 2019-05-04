using System;
using System.Collections.Generic;
using UnityEngine;

namespace Common.Animation
{
    /// <summary>
    /// 动画路径点信息
    /// </summary>
    [Serializable]
    public class AnimationPath
    {
        public string PathName = string.Empty;
        /// <summary>
        /// 操作的对象
        /// </summary>
        public Transform HandleTransform = null;

        /// <summary>
        /// 动画帧信息集合
        /// </summary>
        [SerializeField]
        List<AnimationFrame> m_Frames = new List<AnimationFrame>();

        /// <summary>
        /// 动画帧信息集合
        /// </summary>
        public List<AnimationFrame> Frames
        {
            get { return m_Frames; }
        }

        /// <summary>
        /// 上次更新的拐点
        /// </summary>
        int LastFrameIndex = 0;

        /// <summary>
        /// 重置到开始状态
        /// </summary>
        public void ResetToBeginning()
        {
            LastFrameIndex = 0;
            for (int i = 0; i < m_Frames.Count; i++)
            {
                if (m_Frames[i] != null)
                {
                    m_Frames[i].ResetToBeginning();
                }
            }

            if (HandleTransform != null && m_Frames.Count > 0)
            {
                SetHandleTransform(m_Frames[0]);
                m_Frames[0].FramePlayed();
            }
        }

        /// <summary>
        /// 重置操作的对象的信息
        /// </summary>
        void SetHandleTransform(AnimationFrame frame)
        {
            HandleTransform.localEulerAngles = frame.localRotation;
            HandleTransform.localPosition = frame.localPosition;
            HandleTransform.localScale = frame.localScale;
            HandleTransform.gameObject.SetActive(frame.Active);
        }

        /// <summary>
        /// 更新动画
        /// </summary>
        /// <param name="currentTime"></param>
        public void UpdateAnimation(float currentTime)
        {
            // 根据当前时间设置            
            while (m_Frames.Count > LastFrameIndex + 1)
            {
                AnimationFrame currentFrame = m_Frames[LastFrameIndex];
                AnimationFrame nextFrame = m_Frames[LastFrameIndex + 1];

                if (currentTime < nextFrame.Time)
                {
                    AnimationFrame frame = Leap(currentFrame, nextFrame, currentTime);
                    SetHandleTransform(frame);
                    break;
                }
                else
                {
                    LastFrameIndex += 1;
                    SetHandleTransform(nextFrame);
                    nextFrame.FramePlayed();
                    if (currentTime == nextFrame.Time)
                    {
                        break;
                    }
                }
            }
        }
        /// <summary>
        /// 平滑插值
        /// </summary>
        /// <param name="from"></param>
        /// <param name="to"></param>
        /// <param name="currentTime"></param>
        /// <returns></returns>
        AnimationFrame Leap(AnimationFrame from, AnimationFrame to, float currentTime)
        {
            float deltaTime = currentTime - from.Time;
            float totalTime = to.Time - from.Time;
            float leapValue = deltaTime / totalTime;
            AnimationFrame leap = new AnimationFrame();
            leap.Active = from.Active;
            leap.localPosition = from.localPosition + (to.localPosition - from.localPosition) * leapValue;
            leap.localRotation = from.localRotation + (to.localRotation - from.localRotation) * leapValue;
            leap.localScale = from.localScale + (to.localScale - from.localScale) * leapValue;
            return leap;
        }

    }
}