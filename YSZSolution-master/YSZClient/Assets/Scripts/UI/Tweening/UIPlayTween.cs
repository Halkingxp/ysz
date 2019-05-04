//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************

using UnityEngine;
using System.Collections;
using UnityEngine.UI;

/// <summary>
/// 触发方式
/// </summary>
public enum Trigger
{
    OnClick,
    OnHover,
    OnPress, 
}

/// <summary>
/// 方向
/// </summary>
public enum Direction
{
    Reverse = -1,
    Toggle = 0,
    Forward = 1,
}


/// <summary>
/// UI 2个位置缓动
/// </summary>
[RequireComponent(typeof(TweenPosition))]

public class UIPlayTween : MonoBehaviour {

    private Button _button;
    private TweenPosition _tweenPosition;
    private Direction _direction = Direction.Forward;

    void Awake()
    {
        _button = gameObject.GetComponent<Button>();
        if(_button == null)
        {
            gameObject.AddComponent<Button>();
        }
       _tweenPosition = gameObject.GetComponent<TweenPosition>();        
    }

    public void OnTweenBtnClick()
    {
        _tweenPosition.enabled = true;
        if(_direction == Direction.Forward)
        {
            _tweenPosition.PlayForward();
            _direction = Direction.Reverse;
        }
        else if(_direction == Direction.Reverse)
        {
            _tweenPosition.PlayReverse();
            _direction = Direction.Forward;
        }
    }


}
