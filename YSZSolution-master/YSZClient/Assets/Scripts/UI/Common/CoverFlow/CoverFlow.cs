using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 轮番控制脚本
/// </summary>
[ExecuteInEditMode]
[XLua.LuaCallCSharp]
public class CoverFlow : MonoBehaviour
{
    /// <summary>
    /// Control the "depth"'s curve(In 3d version just the Z value, in 2D UI you can use the depth(NGUI)) 
    /// </summary>
    [SerializeField]
    AnimationCurve depthCurve = new AnimationCurve(new Keyframe(0, 0), new Keyframe(0.5f, 1), new Keyframe(1, 0)) { postWrapMode = WrapMode.Loop, preWrapMode = WrapMode.Loop };

    [SerializeField]
    AnimationCurve positionCurve = null;

    /// <summary>
    /// 高度曲线
    /// </summary>
    [SerializeField]
    AnimationCurve heightCurve = null;

    [SerializeField]
    AnimationCurve scaleCurve = null;

    [SerializeField]
    AnimationCurve rotateZCurve = null;

    /// <summary>
    /// The start center index
    /// </summary>
    [Tooltip("The Start center index")]
    int startCenterIndex = 0;

    /// <summary>
    /// Offset width between item
    /// </summary>
    public float cellWidth = 10f;

    private float totalHorizontalWidth = 500.0f;

    public float RotateFactor = 90;

    public float HeightFactor = 100;

    // Lerp duration
    public float lerpDuration = 0.2f;
    private float mCurrentDuration = 0.0f;

    public bool enableLerpTween = true;

    // center and preCentered item
    private CoverFlowItem curCenterItem;
    private CoverFlowItem preCenterItem;

    // if we can change the target item
    private bool canChangeItem = true;
    private float dFactor = 0.2f;

    // originHorizontalValue Lerp to horizontalTargetValue
    private float originHorizontalValue = 0.1f;
    public float curHorizontalValue = 0.5f;

    private bool m_IsStarted = false;
    /// <summary>
    /// 是否已经经过了Start函数
    /// </summary>
    public bool IsStarted
    {
        get { return m_IsStarted; }
    }


    /// <summary>
    /// 
    /// </summary>
    public List<CoverFlowItem> listCoverFlowItems;
    // sort to get right index
    private List<CoverFlowItem> listSortedItems = new List<CoverFlowItem>();

    /// <summary>
    /// 重置中心Item
    /// </summary>
    /// <param name="index"></param>
    public void ResetCenterItem(int index)
    {
        if (index < 0)
        {
            index = 0;
        }
        if (index > listCoverFlowItems.Count - 1)
        {
            index = listCoverFlowItems.Count - 1;
        }

        if (IsStarted)
        {
            SetHorizontalTargetItemIndex(listCoverFlowItems[index]);
        }
        else
        {
            startCenterIndex = index;
        }
    }

    /// <summary>
    /// 平滑移动
    /// </summary>
    /// <param name="originValue"></param>
    /// <param name="targetValue"></param>
    /// <param name="needTween"></param>
    private void LerpTweenToTarget(float originValue, float targetValue, bool needTween = false)
    {
        if (!needTween)
        {
            SortCoverFlowItems1();
            originHorizontalValue = targetValue;
            UpdateCoverFlowItems(targetValue);
            this.OnTweenOver1();
        }
        else
        {
            originHorizontalValue = originValue;
            curHorizontalValue = targetValue;
            mCurrentDuration = 0.0f;
        }
        enableLerpTween = needTween;
    }

    /// <summary>
    /// Update EnhanceItem state with curve fTime value
    /// </summary>
    /// <param name="timeValue"></param>
    public void UpdateCoverFlowItems(float timeValue)
    {
        foreach (var coverFlowItem in listCoverFlowItems)
        {
            ResetCoverFlowItemPosition1(coverFlowItem, timeValue);
            ResetCoverFlowItemDepth1(coverFlowItem, timeValue);
            ResetCoverFlowItemScale1(coverFlowItem, timeValue);
            ResetCoverFlowRotate1(coverFlowItem, timeValue);
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="item"></param>
    /// <param name="timeValue"></param>
    void ResetCoverFlowItemPosition1(CoverFlowItem item, float timeValue)
    {
        float xValue = GetXPosValue1(timeValue, item.CenterOffSet);
        float yValue = GetYPosValue1(timeValue, item.CenterOffSet);
        item.transform.localPosition = new Vector3(xValue, yValue, 0);
    }

    /// <summary>
    /// 重置Depth
    /// </summary>
    /// <param name="item"></param>
    /// <param name="timeValue"></param>
    void ResetCoverFlowItemDepth1(CoverFlowItem item, float timeValue)
    {
        float depthCurveValue = depthCurve.Evaluate(timeValue + item.CenterOffSet);
        int newDepth = (int)(depthCurveValue * listCoverFlowItems.Count);
        item.transform.SetSiblingIndex(newDepth);
    }

    /// <summary>
    /// 重置Scale
    /// </summary>
    /// <param name="item"></param>
    /// <param name="timeValue"></param>
    void ResetCoverFlowItemScale1(CoverFlowItem item, float timeValue)
    {
        item.transform.localScale = Vector3.one * scaleCurve.Evaluate(timeValue + item.CenterOffSet);
    }

    /// <summary>
    /// 重置Rotation
    /// </summary>
    /// <param name="item"></param>
    /// <param name="timeValue"></param>
    void ResetCoverFlowRotate1(CoverFlowItem item, float timeValue)
    {
        item.transform.localEulerAngles = Vector3.forward * RotateFactor * rotateZCurve.Evaluate(timeValue + item.CenterOffSet);
    }

    /// <summary>
    /// 
    /// </summary>
    private void TweenViewToTarget1()
    {
        mCurrentDuration += Time.deltaTime;
        if (mCurrentDuration > lerpDuration)
            mCurrentDuration = lerpDuration;

        float percent = mCurrentDuration / lerpDuration;
        float value = Mathf.Lerp(originHorizontalValue, curHorizontalValue, percent);
        UpdateCoverFlowItems(value);
        if (mCurrentDuration >= lerpDuration)
        {
            canChangeItem = true;
            enableLerpTween = false;
            OnTweenOver1();
        }
    }

    private void OnTweenOver1()
    {
        for (int i = 0; i < listCoverFlowItems.Count; i++)
        {
            if (listCoverFlowItems[i] != curCenterItem)
            {
                listCoverFlowItems[i].SetSelectState(false);
            }
        }
        if (curCenterItem != null)
            curCenterItem.SetSelectState(true);
    }

    /// <summary>
    /// Get the X value set the Item's position
    /// </summary>
    /// <param name="sliderValue"></param>
    /// <param name="added"></param>
    /// <returns></returns>
    private float GetXPosValue1(float sliderValue, float added)
    {
        float evaluateValue = positionCurve.Evaluate(sliderValue + added) * totalHorizontalWidth;
        return evaluateValue;
    }

    /// <summary>
    /// Get the Y value set the Item's position
    /// </summary>
    /// <param name="timeValue"></param>
    /// <param name="added"></param>
    /// <returns></returns>
    private float GetYPosValue1(float timeValue, float added)
    {
        return heightCurve.Evaluate(timeValue + added) * HeightFactor;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="preCenterItem"></param>
    /// <param name="newCenterItem"></param>
    /// <returns></returns>
    private int GetMoveCurveFactorCount1(CoverFlowItem preCenterItem, CoverFlowItem newCenterItem)
    {
        SortCoverFlowItems1();
        int factorCount = Mathf.Abs(newCenterItem.RealIndex) - Mathf.Abs(preCenterItem.RealIndex);
        return Mathf.Abs(factorCount);
    }

    /// <summary>
    /// sort item with X so we can know how much distance we need to move the timeLine(curve time line)
    /// </summary>
    /// <param name="a"></param>
    /// <param name="b"></param>
    /// <returns></returns>
    public static int SortPosition(CoverFlowItem a, CoverFlowItem b)
    {
        return a.transform.localPosition.x.CompareTo(b.transform.localPosition.x);
    }

    /// <summary>
    /// 
    /// </summary>
    private void SortCoverFlowItems1()
    {
        listSortedItems.Sort(SortPosition);
        for (int i = listSortedItems.Count - 1; i >= 0; i--)
            listSortedItems[i].RealIndex = i;
    }
    /// <summary>
    /// 设置水平方向跟随item
    /// </summary>
    /// <param name="selectItem"></param>
    public void SetHorizontalTargetItemIndex(CoverFlowItem selectItem)
    {
        if (!canChangeItem)
            return;

        if (curCenterItem == selectItem)
            return;

        canChangeItem = false;
        preCenterItem = curCenterItem;
        curCenterItem = selectItem;

        // calculate the direction of moving
        float centerXValue = positionCurve.Evaluate(0.5f) * totalHorizontalWidth;
        bool isRight = false;
        if (selectItem.transform.localPosition.x > centerXValue)
            isRight = true;

        // calculate the offset * dFactor
        int moveIndexCount = GetMoveCurveFactorCount1(preCenterItem, selectItem);
        float dvalue = 0.0f;
        if (isRight)
        {
            dvalue = -dFactor * moveIndexCount;
        }
        else
        {
            dvalue = dFactor * moveIndexCount;
        }
        float originValue = curHorizontalValue;
        LerpTweenToTarget(originValue, curHorizontalValue + dvalue, true);
    }

    /// <summary>
    /// 向右侧移动一个
    /// </summary>
    public void OnMoveToRightOne()
    {
        if (!canChangeItem)
            return;
        int targetIndex = curCenterItem.CurveOffSetIndex + 1;
        if (targetIndex > listCoverFlowItems.Count - 1)
            targetIndex = 0;
        SetHorizontalTargetItemIndex(listCoverFlowItems[targetIndex]);
    }

    /// <summary>
    /// 向左侧移动一个
    /// </summary>
    public void OnMoveToLeftOne()
    {
        if (!canChangeItem)
            return;
        int targetIndex = curCenterItem.CurveOffSetIndex - 1;
        if (targetIndex < 0)
            targetIndex = listCoverFlowItems.Count - 1;
        SetHorizontalTargetItemIndex(listCoverFlowItems[targetIndex]);
    }
    /// <summary>
    /// 拖拽因子
    /// </summary>
    public float factor = 0.001f;
    /// <summary>
    /// On Drag Move
    /// </summary>
    /// <param name="delta"></param>
    public void OnDragEnhanceViewMove(Vector2 delta)
    {
        // In developing
        if (Mathf.Abs(delta.x) > 0.0f)
        {
            curHorizontalValue += delta.x * factor;
            LerpTweenToTarget(0.0f, curHorizontalValue, false);
        }
    }

    /// <summary>
    /// On Drag End
    /// </summary>
    public void OnDragEnhanceViewEnd()
    {
        // find closed item to be centered
        int closestIndex = 0;
        float value = (curHorizontalValue - (int)curHorizontalValue);
        float min = float.MaxValue;
        float tmp = 0.5f * (curHorizontalValue < 0 ? -1 : 1);
        for (int i = 0; i < listCoverFlowItems.Count; i++)
        {
            float dis = Mathf.Abs(Mathf.Abs(value) - Mathf.Abs((tmp - listCoverFlowItems[i].CenterOffSet)));
            if (dis < min)
            {
                closestIndex = i;
                min = dis;
            }
        }
        originHorizontalValue = curHorizontalValue;
        float target = ((int)curHorizontalValue + (tmp - listCoverFlowItems[closestIndex].CenterOffSet));
        preCenterItem = curCenterItem;
        curCenterItem = listCoverFlowItems[closestIndex];
        LerpTweenToTarget(originHorizontalValue, target, true);
        canChangeItem = false;
    }

    void Start()
    {
        canChangeItem = true;
        int count = listCoverFlowItems.Count;
        dFactor = (Mathf.RoundToInt((1f / count) * 10000f)) * 0.0001f;
        int mCenterIndex = count / 2;
        if (count % 2 == 0)
            mCenterIndex = count / 2 - 1;
        int index = 0;
        for (int i = count - 1; i >= 0; i--)
        {
            listCoverFlowItems[i].CurveOffSetIndex = i;
            listCoverFlowItems[i].CenterOffSet = dFactor * (mCenterIndex - index);
            listCoverFlowItems[i].SetSelectState(false);
            listCoverFlowItems[i].SetCoverFlow(this);
            GameObject obj = listCoverFlowItems[i].gameObject;
            index++;
        }

        // set the center item with startCenterIndex
        if (startCenterIndex < 0 || startCenterIndex >= count)
        {
            Debug.LogError("## startCenterIndex < 0 || startCenterIndex >= listEnhanceItems.Count  out of index ##");
            startCenterIndex = mCenterIndex;
        }

        // sorted items
        listSortedItems = new List<CoverFlowItem>(listCoverFlowItems.ToArray());
        totalHorizontalWidth = cellWidth * count;
        curCenterItem = listCoverFlowItems[startCenterIndex];
        curHorizontalValue = 0.5f - curCenterItem.CenterOffSet;
        LerpTweenToTarget(0f, curHorizontalValue, false);
        m_IsStarted = true;
    }

    void Update()
    {
        if (enableLerpTween)
        {
            TweenViewToTarget1();
        }
    }

}