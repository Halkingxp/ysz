using System.Collections.Generic;
using UnityEngine.EventSystems;

namespace UnityEngine.UI
{
    /// <summary>
    /// ScrollRect 扩展
    /// </summary>
    public class ScrollRectExtend : UnityEngine.UI.ScrollRect
    {
        private List<float> _childrenPos = new List<float>();
        /// <summary>
        /// Left 标记
        /// </summary>
        [SerializeField]
        private Button m_LeftArrow = null;

        /// <summary>
        /// Right 标记
        /// </summary>
        [SerializeField]
        private Button m_RightArrow = null;

        /// <summary>
        /// 可见个数
        /// </summary>
        [SerializeField]
        private int m_DisplayItemCount = 5;
        /// <summary>
        /// 半遮挡数量
        /// </summary>
        private int m_HalfShowItemCount = 2;

        /// <summary>
        /// 中心点位置
        /// </summary>
        public int CenterIndex { get; private set; }

        TweenPosition centerAnimation = null;
        bool isAnimation = false;
        protected override void Awake()
        {
            base.Awake();
            GridLayoutGroup grid;
            grid = content.GetComponent<GridLayoutGroup>();
            if (grid == null)
            {
                Debug.LogError("CenterOnChild: No GridLayoutGroup on the ScrollRect's content");
                return;
            }

            //计算第一个子物体位于中心时的位置
            float childPosX = viewRect.rect.width * 0.5f - grid.cellSize.x * 0.5f - grid.spacing.x * 0.5f;
            _childrenPos.Add(childPosX);
            //缓存所有子物体位于中心时的位置
            for (int i = 0; i < content.childCount - 1; i++)
            {
                childPosX -= grid.cellSize.x + grid.spacing.x;
                _childrenPos.Add(childPosX);
            }

            m_HalfShowItemCount = Mathf.CeilToInt(m_DisplayItemCount / 2);
            m_LeftArrow.onClick.AddListener(() => Move(-1));
            m_RightArrow.onClick.AddListener(() => Move(1));
            CenterOnChild(CenterIndex);
        }

        /// <summary>
        /// Drag 开始
        /// </summary>
        /// <param name="eventData"></param>
        public override void OnBeginDrag(PointerEventData eventData)
        {
            base.OnBeginDrag(eventData);
        }

        /// <summary>
        /// Drag结束
        /// </summary>
        /// <param name="eventData"></param>
        public override void OnEndDrag(PointerEventData eventData)
        {
            base.OnEndDrag(eventData);
            destinationX = FindClosestPos(content.localPosition.x);
            StartCenterAnimation();
        }

        /// <summary>
        /// 开始中心动画
        /// </summary>
        void StartCenterAnimation()
        {
            centerAnimation = TweenPosition.Begin(content.gameObject, 0.4f, new Vector3(destinationX, 0, 0), false);
            centerAnimation.OnFinished -= StopCenterAnimation;
            centerAnimation.OnFinished += StopCenterAnimation;
            centerAnimation.enabled = true;
            centerAnimation.Play(true);
            isAnimation = true;
        }

        /// <summary>
        /// 停止中心动画
        /// </summary>
        void StopCenterAnimation()
        {
            centerAnimation.enabled = false;
            content.localPosition = centerAnimation.to;
            UpdateArrow(content.localPosition.x);
        }

        /// <summary>
        /// Drag 中
        /// </summary>
        /// <param name="eventData"></param>
        public override void OnDrag(PointerEventData eventData)
        {
            base.OnDrag(eventData);
            isAnimation = false;
        }

        /// <summary>
        /// 设置Content Anchored Position
        /// </summary>
        /// <param name="position"></param>
        protected override void SetContentAnchoredPosition(Vector2 position)
        {
            if (!isAnimation)
            {
                base.SetContentAnchoredPosition(position);
            }
            UpdateArrow(content.localPosition.x);
        }

        private float destinationX = 0f;

        /// <summary>
        /// 更新箭头是否显示
        /// </summary>
        /// <param name="currentPos"></param>
        private void UpdateArrow(float currentPos)
        {
            int childIndex = 0;
            float distance = Mathf.Infinity;

            for (int i = 0; i < _childrenPos.Count; i++)
            {
                float pos = _childrenPos[i];
                float d = Mathf.Abs(pos - currentPos);
                if (d < distance)
                {
                    distance = d;
                    childIndex = i;
                }
            }

            if (m_LeftArrow != null)
            {
                m_LeftArrow.gameObject.SetActive(childIndex < _childrenPos.Count - m_HalfShowItemCount - 1);
            }

            if (m_RightArrow != null)
            {
                m_RightArrow.gameObject.SetActive(childIndex > m_HalfShowItemCount);
            }
        }
        /// <summary>
        /// 查找停止pos
        /// </summary>
        /// <param name="currentPos"></param>
        /// <returns></returns>
        private float FindClosestPos(float currentPos)
        {
            float closest = 0;
            float distance = Mathf.Infinity;
            int childIndex = 0;
            for (int i = 0; i < _childrenPos.Count; i++)
            {
                float p = _childrenPos[i];
                float d = Mathf.Abs(p - currentPos);
                if (d < distance)
                {
                    distance = d;
                    closest = p;
                    childIndex = i;
                }
            }
            CenterIndex = childIndex;
            return closest;
        }

        /// <summary>
        /// 设置中心child
        /// </summary>
        /// <param name="index"></param>
        /// <param name="isAni"></param>
        public void CenterOnChild(int index, bool isAni = false)
        {
            if (_childrenPos.Count > 0)
            {
                if (index < m_HalfShowItemCount)
                {
                    index = m_HalfShowItemCount;
                }
                else if (index > _childrenPos.Count - m_HalfShowItemCount - 1)
                {
                    index = _childrenPos.Count - m_HalfShowItemCount - 1;
                }

                destinationX = _childrenPos[index];
                CenterIndex = index;

                if (isAni)
                {
                    StartCenterAnimation();
                }
                else
                {
                    Vector3 v = content.localPosition;
                    v.x = destinationX;
                    content.localPosition = v;
                    UpdateArrow(content.localPosition.x);
                }
            }
            else
            {
                CenterIndex = index;
            }
        }

        /// <summary>
        /// 移动
        /// </summary>
        /// <param name="moveSpace">左移动 负数， 右移动 正数</param>
        public void Move(int moveSpace)
        {
            CenterOnChild(CenterIndex - moveSpace, true);
        }

    }
}