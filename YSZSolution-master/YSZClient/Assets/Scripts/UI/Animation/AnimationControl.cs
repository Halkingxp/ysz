using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 动画相关
/// </summary>
namespace Common.Animation
{
    /// <summary>
    /// 荷官洗牌动画(AnimationControl)
    /// </summary>
    public class AnimationControl : MonoBehaviour
    {
        public const string FrameComplated = "FrameComplated";

        [SerializeField]
        string m_AnimationName = "";
        /// <summary>
        /// 动画名称
        /// </summary>
        public string AnimationName
        {
            get { return m_AnimationName; }
            set
            {
                if (!string.IsNullOrEmpty(value) && value != m_AnimationName)
                {
                    RemoveAnimation(m_AnimationName, this);
                    AddAnimation(value, this);
                    m_AnimationName = value;
                }
            }
        }

        /// <summary>
        /// 播放速度
        /// </summary>
        public float speed = 1;

        #region Static Part for use simple

        static Dictionary<string, List<AnimationControl>> aniControlDict = new Dictionary<string, List<AnimationControl>>();

        /// <summary>
        /// 播放某个动画
        /// </summary>
        /// <param name="animationName"></param>
        public static void PlayAnimation(string animationName, float startTime = 0, bool force = true)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                List<AnimationControl> animations = aniControlDict[animationName];
                for (int i = 0; i < animations.Count; i++)
                {
                    animations[i].Play(startTime, force);
                }
            }
        }

        /// <summary>
        /// 停止动画
        /// </summary>
        /// <param name="animationName">动画名称</param>
        /// <param name="isForceToEnd">强制移动到最后</param>
        public static void StopAnimation(string animationName, bool isForceToEnd = true)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                List<AnimationControl> animations = aniControlDict[animationName];
                for (int i = 0; i < animations.Count; i++)
                {
                    animations[i].Stop(isForceToEnd);
                }
            }
        }

        /// <summary>
        /// 暂停动画
        /// </summary>
        /// <param name="animationName">动画名称</param>
        /// <param name="isPause">暂停(true)/继续(false)</param>
        public static void PauseAnimation(string animationName, bool isPause)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                List<AnimationControl> animations = aniControlDict[animationName];
                for (int i = 0; i < animations.Count; i++)
                {
                    animations[i].Pause(isPause);
                }
            }
        }

        /// <summary>
        /// 添加动画
        /// </summary>
        /// <param name="animationName"></param>
        /// <param name="control"></param>
        static void AddAnimation(string animationName, AnimationControl control)
        {
            List<AnimationControl> animations = null;
            if (!aniControlDict.ContainsKey(animationName))
            {
                animations = new List<AnimationControl>();
                aniControlDict.Add(animationName, animations);
            }
            else
            {
                animations = aniControlDict[animationName];
            }

            if (!animations.Contains(control))
            {
                animations.Add(control);
            }
        }

        /// <summary>
        /// 移除动画
        /// </summary>
        /// <param name="animationName"></param>
        /// <param name="control"></param>
        static void RemoveAnimation(string animationName, AnimationControl control)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                if (aniControlDict[animationName].Contains(control))
                {
                    aniControlDict[animationName].Remove(control);
                }
                if (aniControlDict[animationName].Count == 0)
                {
                    aniControlDict.Remove(animationName);
                }
            }
        }

        public static List<AnimationControl> FindAnimationControls(string animationName)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                return aniControlDict[animationName];
            }
            return null;
        }

        public static AnimationControl FindAnimationControl(string animationName)
        {
            if (aniControlDict.ContainsKey(animationName))
            {
                var animations = aniControlDict[animationName];
                if (animations.Count > 0)
                    return animations[0];
                else
                {
                    aniControlDict.Remove(animationName);
                    return null;
                }
            }
            else
            {
                return null;
            }
        }

        #endregion

        /// <summary>
        /// 播放模式
        /// </summary>
        public enum PlayStyle
        {
            Once,
            Loop,
        }

        [SerializeField]
        PlayStyle m_Style = PlayStyle.Once;

        /// <summary>
        /// 动画播放类型
        /// </summary>
        public PlayStyle AniPlayStyle
        {
            get { return m_Style; }
            set { m_Style = value; }
        }

        /// <summary>
        /// 动画当前时间
        /// </summary>
        [SerializeField]
        float m_CurrentTime = 0;

        [SerializeField]
        float m_AnimationTime = 1f;
        /// <summary>
        /// 动画时长
        /// </summary>
        public float AnimationTime
        {
            get { return m_AnimationTime; }
            set { m_AnimationTime = value; }
        }

        /// <summary>
        /// 是否播放完毕
        /// </summary>
        bool isComplated = false;
        /// <summary>
        /// 是否暂停
        /// </summary>
        bool isPause = false;
        /// <summary>
        /// 是否播放
        /// </summary>
        bool isPlaying = false;

        /// <summary>
        /// 自身的动画路径
        /// </summary>
        [SerializeField]
        List<AnimationPath> m_AnimationPaths = new List<AnimationPath>();

        public List<AnimationPath> AnimationPaths { get { return m_AnimationPaths; } }

        /// <summary>
        /// 播放
        /// </summary>
        public void Play(float currentTime = 0, bool force = true)
        {
            if (isPlaying && !force)
            {
                return;
            }
            else
            {
                if (force)
                {
                    enabled = true;
                }
            }
            isPlaying = true;
            ResetToBeginning();
            UpdateAnimation(currentTime);
            isPause = false;
        }

        /// <summary>
        /// 停止动画
        /// </summary>
        /// <param name="isForceToEnd">强制动画停止在最后帧</param>
        public void Stop(bool isForceToEnd = true)
        {
            enabled = false;
            if (isForceToEnd)
            {
                MoveToEnd();
                isPause = false;
                isComplated = true;
            }
        }

        /// <summary>
        /// 动画移动到最后
        /// </summary>
        public void MoveToEnd()
        {
            UpdateAnimation(this.m_AnimationTime);
            isComplated = true;
            isPause = true;
        }

        /// <summary>
        /// 重置动画
        /// </summary>
        public void ResetToBeginning()
        {
            m_CurrentTime = 0f;
            isComplated = false;
            for (int index = 0; index < m_AnimationPaths.Count; index++)
            {
                AnimationPath path = m_AnimationPaths[index];
                if (path != null)
                {
                    path.ResetToBeginning();
                }
            }
        }

        /// <summary>
        /// 暂停动画
        /// </summary>
        /// <param name="pause">是否暂停</param>
        public void Pause(bool pause)
        {
            if (this.isPause != pause)
            {
                this.isPause = pause;
            }
        }

        /// <summary>
        /// 更新动画
        /// </summary>
        void UpdateAnimation(float deltaTime)
        {
            if (isPause)
                return;

            if (!isComplated)
            {
                m_CurrentTime += deltaTime * speed;
                if (m_CurrentTime < this.m_AnimationTime)
                {
                    isComplated = false;
                }
                else
                {
                    if (this.m_Style == PlayStyle.Loop)
                    {
                        Play(0);
                    }
                    else
                    {
                        isComplated = true;
                        isPlaying = false;
                    }
                }

                for (int index = 0; index < m_AnimationPaths.Count; index++)
                {
                    AnimationPath path = m_AnimationPaths[index];
                    if (path != null)
                    {
                        path.UpdateAnimation(m_CurrentTime);
                    }
                }
            }
        }

        protected virtual void Awake()
        {
            if (string.IsNullOrEmpty(m_AnimationName))
            {
                m_AnimationName = gameObject.name;
            }

            AddAnimation(m_AnimationName, this);
        }

        protected virtual void OnDestroy()
        {
            RemoveAnimation(m_AnimationName, this);
        }

        protected virtual void Update()
        {
            UpdateAnimation(Time.unscaledDeltaTime);
        }

    }
}