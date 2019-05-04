//***************************************************************
// 脚本名称：TogglePlayAudio.cs
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************

using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Toggle))]
public class TogglePlayAudio : MonoBehaviour
{
    /// <summary>
    /// 音效ID
    /// </summary>
    public int AudioID = 0;
    /// <summary>
    /// audio 时长
    /// </summary>
    private int audioTime = -1;
    /// <summary>
    /// 播放音效的时间
    /// </summary>
    private int playAudioTime = 0;

    /// <summary>
    /// 事件触发
    /// </summary>
    /// <param name="change"></param>
    void OnValueChange(bool change)
    {

        if (change)
        {
            if (audioTime == -1)
            {
                object[] result = LuaManager.CallMethod("MusicMgr", "GetSoundAudioTime", AudioID);
                if (result.Length > 0)
                {
                    audioTime = System.Convert.ToInt32(result[0]);
                }
            }
            if (Time.time * 1000 - playAudioTime >= audioTime)
            {
                LuaManager.CallMethod("MusicMgr", "PlaySoundAudio", AudioID);
                playAudioTime = (int)(Time.time * 1000);
            }
        }
    }

    // Use this for initialization
    void Start()
    {
        gameObject.GetComponent<Toggle>().onValueChanged.AddListener(OnValueChange);
    }


}
