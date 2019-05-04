using System.Collections.Generic;
using System;
using UnityEngine;


/// <summary>
/// 切牌Item
/// </summary>
public class ItemMoveScript : MonoBehaviour
{
    /// <summary>
    /// 移动结束事件
    /// </summary>
    Action m_onMoveEnd;
    /// <summary>
    /// 结束地点
    /// </summary>
    Vector2 m_endPoint;
    /// <summary>
    /// 速度
    /// </summary>
    float m_speed;
    /// <summary>
    /// 方向
    /// </summary>
    Vector2 m_direction;
    /// <summary>
    /// 是否移动
    /// </summary>
    bool isMoving = false;
    /// <summary>
    /// 控制组件
    /// </summary>
    RectTransform mrect;


    public void StartMove(Vector2 endPoint, float speed, Action func)
    {
        if (mrect == null)
        {
            mrect = this.GetComponent<RectTransform>();
        }
        if ((endPoint - mrect.anchoredPosition).magnitude < 5)
        {
            Debug.LogError("移动的结束点和当前点距离过近，不能移动");
            return;
        }
        m_speed = speed;
        m_endPoint = endPoint;
        m_onMoveEnd = func;
        m_direction = (endPoint - mrect.anchoredPosition).normalized;
        isMoving = true;
    }

    // Update is called once per frame
    void Update()
    {
        if (isMoving == true)
        {
            mrect.anchoredPosition += m_speed * m_direction * Time.deltaTime;
            if (Vector2.Dot(m_endPoint - mrect.anchoredPosition, m_direction) < 0)// 用两个向量的点积的结果是否大于0来判断向量的夹角
            {
                mrect.anchoredPosition = m_endPoint;
                isMoving = false;
                if (m_onMoveEnd != null)
                {
                    m_onMoveEnd.Invoke();
                }
            }
        }
    }

    private void OnDisable()
    {
        isMoving = false;
    }

}
