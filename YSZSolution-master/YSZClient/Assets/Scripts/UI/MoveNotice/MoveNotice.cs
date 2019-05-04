using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;

/// <summary>
/// 走马灯提示UI
/// </summary>
public class MoveNotice : MonoBehaviour
{
    /// <summary>
    /// 遮挡组件
    /// </summary>
    [SerializeField]
    GameObject mMaskGameObject = null;
    /// <summary>
    /// 移动信息内容
    /// </summary>
    [SerializeField]
    Text mMoveNoticeText = null;

    /// <summary>
    /// 半视窗宽度
    /// </summary>
    float mHalfViewWidth = 0f;

    /// <summary>
    /// 通知内容的一半宽度 + 视窗一半宽度
    /// </summary>
    float mHalfNoticeWidth = 0f;

    private static int mMoveSpeed = 100;
    /// <summary>
    /// 通知文字移动速度
    /// </summary>
    public static int MoveSpeed
    {
        get { return mMoveSpeed; }
        set
        {
            if (mMoveSpeed < 1)
                mMoveSpeed = 1;
            if (mMoveSpeed > 10000)
                mMoveSpeed = 10000;

            mMoveSpeed = value;
        }
    }

    private static int mValidTime = 20;

    /// <summary>
    /// 有效的时间(s)单位--最短有效时间5s，最长100s
    /// </summary>
    public static int ValidTime
    {
        get { return mValidTime; }
        set
        {
            if (value < 5)
                value = 5;
            if (value > 100)
                value = 100;

            mValidTime = value;
        }
    }

    /// <summary>
    /// 播放消息队列
    /// </summary>
    static List<NoticeInfo> m_NoticeQueue = new List<NoticeInfo>();

    static List<NoticeInfo> m_NoticedHistory = new List<NoticeInfo>();
    /// <summary>
    /// 播放消息的历史记录
    /// </summary>
    public static List<string> NiticedHistory
    {
        get
        {
            List<string> result = new List<string>();
            for (int i = 0; i < m_NoticedHistory.Count; i++)
            {
                result.Add(m_NoticedHistory[i].Content);
            }

            return result;
        }
    }

    /// <summary>
    /// 系统广播，最大保留20条
    /// </summary>
    public static int HistoryMaxCount = 20;

    static void PushToNiticedHistory(NoticeInfo noticeInfo)
    {
        if (m_NoticedHistory.Count > 1 && noticeInfo == m_NoticedHistory[0])// 已经添加了，不需要添加
        {
            return;
        }

        if (m_NoticedHistory.Count >= HistoryMaxCount)
        {
            m_NoticedHistory.RemoveAt(HistoryMaxCount - 1);
        }

        m_NoticedHistory.Insert(0, noticeInfo);// 插入到最前面
    }

    /// <summary>
    /// 当前播放消息
    /// </summary>
    static NoticeInfo CurrentNotice = null;

    private static int m_MaxCount = 20;
    /// <summary>
    /// 最大保留的消息条目，如果大于此数，则不接受新消息
    /// </summary>
    public static int MaxCount
    {
        get { return m_MaxCount; }
        set
        {
            if (value < 1)
                value = 1;
            m_MaxCount = value;
        }
    }

    /// <summary>
    /// 开始移动标志
    /// </summary>
    static bool MoveStart = false;

    static int m_NoticeID = 1;
    /// <summary>
    /// 获取通知消息序列号
    /// </summary>
    /// <returns></returns>
    static int GetNoticeID()
    {
        if (m_NoticeID > 10000)
        {
            m_NoticeID = 1;
        }
        m_NoticeID++;
        return m_NoticeID;
    }

    int m_PlayingNoticeID = 0;

    /// <summary>
    /// 通知消息
    /// </summary>
    /// <param name="content">消息内容</param>
    /// <param name="level">消息级别</param>
    /// <param name="immediate">是否立即生效(是:播放完当前条目就播放下一条，否:播放完队列中所有才开始播放此消息）</param>
    public static void Notice(string content, int level = 1, bool immediate = false)
    {
        if (m_NoticeQueue.Count > MaxCount)
        {
            //ClearOneObsoleteNotice();
            return;
        }

        NoticeInfo notice = new NoticeInfo(GetNoticeID());
        notice.Content = content;
        notice.PushTime = Time.realtimeSinceStartup;
        notice.Level = level;

        AppendOneNotice(notice);
        MoveStart = true;
    }

    /// <summary>
    /// 清理掉一个最早添加的消息
    /// </summary>
    static void ClearOneObsoleteNotice()
    {
        NoticeInfo notice = m_NoticeQueue[0];
        for (int i = 1; i < m_NoticeQueue.Count; i++)
        {
            // 时间越小越早进入广播等待
            if (m_NoticeQueue[i].PushTime < notice.PushTime)
            {
                notice = m_NoticeQueue[i];
            }
        }
        m_NoticeQueue.Remove(notice);
    }

    static void AppendOneNotice(NoticeInfo notice)
    {
        for (int i = 0; i < m_NoticeQueue.Count; i++)
        {
            if (m_NoticeQueue[i].Level < notice.Level)
            {
                m_NoticeQueue.Insert(i, notice);
                return;
            }
        }

        m_NoticeQueue.Add(notice);
    }

    /// <summary>
    /// 清理掉未播放的消息
    /// </summary>
    public static void ClearAll()
    {
        m_NoticeQueue.Clear();
        if (CurrentNotice != null)
        {
            CurrentNotice = null;
        }
        m_NoticedHistory.Clear();
    }


    bool TryStartMove1()
    {
        bool isStartMoving = false;
        while (m_NoticeQueue.Count > 0)
        {
            NoticeInfo notice = m_NoticeQueue[0];
            //押入到已经播放的列表中
            PushToNiticedHistory(notice);

            if (notice.PushTime - Time.realtimeSinceStartup < ValidTime)// 在有效时间内，消息广播
            {
                m_NoticeQueue.RemoveAt(0);
                CurrentNotice = notice;
                isStartMoving = true;
                RefreshPlayNoticeContent1(notice);
                ResetNoticeTextPosition();
                m_PlayingNoticeID = notice.NoticeID;
                break;
            }
            else
            {
                m_NoticeQueue.RemoveAt(0);
            }
        }
        Debug.LogFormat("IsStartMoving:{0}", isStartMoving);
        return isStartMoving;
    }

    /// <summary>
    /// 重置播放内容
    /// </summary>
    /// <param name="notice">消息内容</param>
    void RefreshPlayNoticeContent1(NoticeInfo notice)
    {
        mMaskGameObject.SetActive(true);
        mMoveNoticeText.text = notice.Content;
        mHalfNoticeWidth = mMoveNoticeText.preferredWidth * 0.5f + mHalfViewWidth;
        mMoveNoticeText.rectTransform.sizeDelta = new Vector2(mMoveNoticeText.preferredWidth, mMoveNoticeText.rectTransform.sizeDelta.y);
        if (notice.StartTime == 0)
        {
            notice.StartTime = Time.realtimeSinceStartup;
        }
    }

    /// <summary>
    /// 重置播放内容位置
    /// </summary>
    void ResetNoticeTextPosition()
    {
        float currentX = mHalfNoticeWidth - (Time.realtimeSinceStartup - CurrentNotice.StartTime) * MoveSpeed;
        mMoveNoticeText.rectTransform.localPosition = new Vector3(currentX, 0, 0);
    }

    /// <summary>
    /// 是否当前条目播放完成
    /// </summary>
    /// <returns></returns>
    bool IsNoticeComplated()
    {
        return mMoveNoticeText.rectTransform.localPosition.x < -mHalfNoticeWidth;
    }

    /// <summary>
    /// 处理播放完成所有消息后的处理
    /// </summary>
    void HandleAllNoticeComplated1()
    {
        CurrentNotice = null;
        mMaskGameObject.SetActive(false);
        MoveStart = false;
        m_PlayingNoticeID = 0;
    }

    private void Awake()
    {
        mHalfViewWidth = GetComponent<RectTransform>().rect.size.x * 0.5f;
        if (mMaskGameObject == null || mMoveNoticeText == null)
        {
            Debug.LogError("Some UI element was null in MoveNotice script, please check it!");
            GameObject.Destroy(this);
        }
    }

    void OnEnable()
    {
        if (CurrentNotice != null)// 重新设置下内容
        {
            RefreshPlayNoticeContent1(CurrentNotice);
        }
        else if (MoveStart)
        {
            Update();
        }
        else
        {
            HandleAllNoticeComplated1();
        }
    }

    /// <summary>
    /// sdfsdfsdf
    /// </summary>
    void Update()
    {
        if (CurrentNotice != null)
        {
            if (m_PlayingNoticeID != CurrentNotice.NoticeID)
            {
                RefreshPlayNoticeContent1(CurrentNotice);
                m_PlayingNoticeID = CurrentNotice.NoticeID;
            }

            ResetNoticeTextPosition();
            if (IsNoticeComplated())
            {
                CurrentNotice = null;
                if (!TryStartMove1())
                {
                    HandleAllNoticeComplated1();
                }
            }
        }
        else if (MoveStart)
        {
            if (!TryStartMove1())
            {
                HandleAllNoticeComplated1();
            }
        }
        else
        {
            if (m_PlayingNoticeID != 0)
            {
                HandleAllNoticeComplated1();
            }
        }
    }

    public class NoticeInfo
    {
        public NoticeInfo(int noticeID)
        {
            this.NoticeID = noticeID;
        }

        /// <summary>
        /// 播放消息的编号
        /// </summary>
        public int NoticeID { get; private set; }

        /// <summary>
        /// 移动文本
        /// </summary>
        public string Content { get; set; }

        /// <summary>
        /// 压入队列的时间
        /// </summary>
        public float PushTime { get; set; }

        /// <summary>
        /// 开始执行时间
        /// </summary>
        public float StartTime { get; set; }

        /// <summary>
        /// 级别
        /// </summary>
        public int Level { get; set; }
    }

}