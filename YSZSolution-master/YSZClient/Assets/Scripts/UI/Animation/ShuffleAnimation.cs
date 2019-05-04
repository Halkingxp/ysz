using UnityEngine;
using Common.Animation;

/// <summary>
/// 庄家洗牌动画
/// </summary>
[RequireComponent(typeof(AnimationControl))]
public class ShuffleAnimation : MonoBehaviour
{
    /// <summary>
    /// 洗牌时间间隔
    /// </summary>
    public float m_CardInterval = 0.03f;
    /// <summary>
    /// 扑克牌数量
    /// </summary>
    public int CardMax = 16;
    /// <summary>
    /// 上方显示时间
    /// </summary>
    public float shangDisPlayTime = 0.03f;
    /// <summary>
    /// 中间显示时间
    /// </summary>
    public float zhongDisplayTime = 0.03f;
    /// <summary>
    /// 扑克牌
    /// </summary>
    public GameObject m_OneGroupCard = null;
    /// <summary>
    /// 洗牌父节点
    /// </summary>
    public Transform m_ShuffleCardRoot = null;
    /// <summary>
    /// 飞牌时间
    /// </summary>
    public float flyCardTime = 0.05f;
    /// <summary>
    /// 飞牌组件
    /// </summary>
    public Transform m_FlyPokerCard = null;
    /// <summary>
    /// 飞牌组件父节点
    /// </summary>
    public Transform m_FlyPokerCardRoot = null;

    /// <summary>
    /// 高度间隔
    /// </summary>
    float SpaceY = 5;

    /// <summary>
    /// 荷官洗牌控制器
    /// </summary>
    AnimationControl m_AnimationControl = null;

    /// <summary>
    /// 初始化Left动画组件
    /// </summary>
    /// <param name="leftRoot"></param>
    /// <param name="index"></param>
    /// <param name="disappearOffsetTime"></param>
    void InitOneLeftAnimationPath(Transform leftRoot, int index, float disappearOffsetTime = 1f)
    {
        float startTime = m_CardInterval * index * 2;
        AnimationPath leftShangPath = new AnimationPath();
        leftShangPath.PathName = "left_shang_" + index;
        leftShangPath.HandleTransform = leftRoot.Find("Item_shang");
        leftShangPath.Frames.Add(new AnimationFrame(leftShangPath.HandleTransform) { Time = 0, Active = true });
        leftShangPath.Frames.Add(new AnimationFrame(leftShangPath.HandleTransform) { Time = startTime + shangDisPlayTime, Active = false });
        this.m_AnimationControl.AnimationPaths.Add(leftShangPath);

        AnimationPath leftZhongPath = new AnimationPath();
        leftZhongPath.PathName = "left_zhong_" + index;
        leftZhongPath.HandleTransform = leftRoot.Find("Item_zhong");
        leftZhongPath.Frames.Add(new AnimationFrame(leftZhongPath.HandleTransform) { Time = 0, Active = false });
        // 上消失，中出现
        leftZhongPath.Frames.Add(new AnimationFrame(leftZhongPath.HandleTransform) { Time = startTime + shangDisPlayTime, Active = true });
        leftZhongPath.Frames.Add(new AnimationFrame(leftZhongPath.HandleTransform) { Time = startTime + shangDisPlayTime + zhongDisplayTime, Active = false });
        this.m_AnimationControl.AnimationPaths.Add(leftZhongPath);

        AnimationPath leftXiaPath = new AnimationPath();
        leftXiaPath.PathName = "left_xia_" + index;
        leftXiaPath.HandleTransform = leftRoot.Find("Item_xia");
        leftXiaPath.Frames.Add(new AnimationFrame(leftXiaPath.HandleTransform) { Time = 0, Active = false });
        // 中消失，下出现
        leftXiaPath.Frames.Add(new AnimationFrame(leftXiaPath.HandleTransform) { Time = startTime + shangDisPlayTime + zhongDisplayTime, Active = true });
        // 下消失，飞牌开始      
        leftXiaPath.Frames.Add(new AnimationFrame(leftXiaPath.HandleTransform) { Time = disappearOffsetTime + flyCardTime * (CardMax - index) * 2, Active = false });
        this.m_AnimationControl.AnimationPaths.Add(leftXiaPath);
    }

    /// <summary>
    /// 初始化Right动画组件
    /// </summary>
    /// <param name="rightRoot"></param>
    /// <param name="index"></param>
    /// <param name="disappearOffsetTime"></param>
    void InitRightAnimationPath(Transform rightRoot, int index, float disappearOffsetTime = 1f)
    {
        float startTime = m_CardInterval * (index * 2 + 1);
        AnimationPath rightShangPath = new AnimationPath();
        rightShangPath.PathName = "right_shang_" + index;
        rightShangPath.HandleTransform = rightRoot.Find("Item_shang");
        rightShangPath.Frames.Add(new AnimationFrame(rightShangPath.HandleTransform) { Time = 0, Active = true });
        rightShangPath.Frames.Add(new AnimationFrame(rightShangPath.HandleTransform) { Time = startTime + shangDisPlayTime, Active = false });
        this.m_AnimationControl.AnimationPaths.Add(rightShangPath);

        AnimationPath rightZhongPath = new AnimationPath();
        rightZhongPath.PathName = "right_zhong_" + index;
        rightZhongPath.HandleTransform = rightRoot.Find("Item_zhong");
        rightZhongPath.Frames.Add(new AnimationFrame(rightZhongPath.HandleTransform) { Time = 0, Active = false });
        // 上消失，中出现
        rightZhongPath.Frames.Add(new AnimationFrame(rightZhongPath.HandleTransform) { Time = startTime + shangDisPlayTime, Active = true });
        rightZhongPath.Frames.Add(new AnimationFrame(rightZhongPath.HandleTransform) { Time = startTime + shangDisPlayTime + zhongDisplayTime, Active = false });
        this.m_AnimationControl.AnimationPaths.Add(rightZhongPath);

        AnimationPath rightXiaPath = new AnimationPath();
        rightXiaPath.PathName = "right_xia_" + index;
        rightXiaPath.HandleTransform = rightRoot.Find("Item_xia");
        rightXiaPath.Frames.Add(new AnimationFrame(rightXiaPath.HandleTransform) { Time = 0, Active = false });
        // 中消失，下出现
        rightXiaPath.Frames.Add(new AnimationFrame(rightXiaPath.HandleTransform) { Time = startTime + shangDisPlayTime + zhongDisplayTime, Active = true });
        // 下消失，飞牌开始
        rightXiaPath.Frames.Add(new AnimationFrame(rightXiaPath.HandleTransform) { Time = disappearOffsetTime + flyCardTime * ((CardMax - index) * 2 - 1), Active = false });
        this.m_AnimationControl.AnimationPaths.Add(rightXiaPath);
    }

    /// <summary>
    /// 初始化飞牌动画组件
    /// </summary>
    /// <param name="cardTrans"></param>
    /// <param name="index"></param>
    /// <param name="offsetTime"></param>
    void InitCardFlyAnimationPath(Transform cardTrans, int index, float offsetTime)
    {
        float startTime = offsetTime + flyCardTime * index;
        AnimationPath flyAniPath = new AnimationPath();
        flyAniPath.HandleTransform = cardTrans;
        flyAniPath.PathName = "fly_animation_" + index;
        Vector3 startScale = Vector3.one * 0.4f;
        Vector3 startPoint = new Vector3(0, -30 - index * SpaceY * 0.4f, 0);

        Vector3 endScale = Vector3.one * 1.2f;
        Vector3 endPoint = new Vector3(0, -400 + index * SpaceY, 0);

        flyAniPath.Frames.Add(new AnimationFrame() { Time = 0, Active = false, localScale = startScale, localPosition = startPoint });
        flyAniPath.Frames.Add(new AnimationFrame() { Time = startTime, Active = true, localScale = startScale, localPosition = startPoint });
        flyAniPath.Frames.Add(new AnimationFrame() { Time = startTime + flyCardTime, Active = true, localScale = endScale, localPosition = endPoint });
        this.m_AnimationControl.AnimationPaths.Add(flyAniPath);
    }

    protected void Awake()
    {
        if (m_OneGroupCard == null || m_ShuffleCardRoot == null || m_FlyPokerCard == null)
        {
            Debug.LogError("Some ui element was null in ShuffleAnimation script, please check it!");
            return;
        }

        this.m_AnimationControl = GetComponent<AnimationControl>();
        this.m_AnimationControl.AnimationName = "ShuffleAnimation";
        //this.m_AnimationControl.speed = 0.01f;
        this.m_AnimationControl.AniPlayStyle = AnimationControl.PlayStyle.Once;

        // 第二段 飞牌动画的偏移时间
        // 第一段动画总共时间：动画间隔 + 动画时长 + 0.1
        float offsetTime = m_CardInterval * CardMax * 2 + shangDisPlayTime + zhongDisplayTime + 0.1f;
        for (int index = 0; index < CardMax; index++)
        {
            GameObject go = Instantiate(m_OneGroupCard);
            go.name = string.Format("CardGroup ({0})", index + 1);
            Utility.ReSetTransform(go.transform, m_ShuffleCardRoot);
            go.transform.localPosition = new Vector3(0, index * SpaceY, 0);
            go.SetActive(true);
            InitOneLeftAnimationPath(go.transform.Find("LeftItem"), index, offsetTime);
            InitRightAnimationPath(go.transform.Find("RightItem"), index, offsetTime);
        }

        // 第二段动画，从A点飞到B点，缩放
        for (int index = 0; index < CardMax * 2; index++)
        {
            Transform cardTrans = Instantiate(m_FlyPokerCard);
            cardTrans.name = (index + 1).ToString();
            Utility.ReSetTransform(cardTrans, m_FlyPokerCardRoot);
            cardTrans.localPosition = new Vector3(0, index * SpaceY, 0);
            cardTrans.gameObject.SetActive(true);
            InitCardFlyAnimationPath(cardTrans, index, offsetTime);
        }

        this.m_AnimationControl.AnimationTime = offsetTime + (CardMax * 2 * flyCardTime) + 0.1f;
    }

}