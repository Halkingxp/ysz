using System;
using UnityEngine;

namespace Common.Animation
{
    /// <summary>
    /// 拐点信息
    /// </summary>
    [Serializable]
    public class AnimationFrame
    {
        public AnimationFrame()
        {

        }

        public AnimationFrame(Transform transform)
        {
            if (transform == null)
                return;

            this.localRotation = transform.localEulerAngles;
            this.localPosition = transform.localPosition;
            this.localScale = transform.localScale;
            this.Active = transform.gameObject.activeSelf;
        }
        
        /// <summary>
        /// 帧开始时间
        /// </summary>
        public float Time = 0f;
        /// <summary>
        /// 本地信息
        /// </summary>
        public Vector3 localPosition = Vector3.zero;
        /// <summary>
        /// 拐点的朝向
        /// </summary>
        public Vector3 localRotation = Vector3.zero;
        /// <summary>
        /// 当前节点的缩放
        /// </summary>
        public Vector3 localScale = Vector3.one;
        /// <summary>
        /// 是否可见
        /// </summary>
        public bool Active = false;

        /// <summary>
        /// 是否通知了当前节点
        /// </summary>
        public bool IsPlayed { get; private set; }
        /// <summary>
        /// 重置到开始状态
        /// </summary>
        public void ResetToBeginning()
        {
            IsPlayed = false;
        }

        /// <summary>
        /// 是否通知
        /// </summary>
        public bool IsNotifyEvent = false;
        /// <summary>
        /// 用户自定义数据
        /// </summary>
        public string UserData = string.Empty;

        /// <summary>
        /// 当前帧播放了
        /// </summary>
        public void FramePlayed()
        {
            IsPlayed = true;
            try
            {
                if (IsNotifyEvent)
                {
                    EventDispatcher.Instance.TriggerEvent(AnimationControl.FrameComplated, UserData);
                }
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
            }
        }

    }
}