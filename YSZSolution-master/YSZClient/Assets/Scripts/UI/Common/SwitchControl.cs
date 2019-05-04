using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using System;

/// <summary>
/// 开关控制按钮
/// </summary>
[ExecuteInEditMode]
public class SwitchControl : MonoBehaviour, IPointerClickHandler
{
    public Toggle.ToggleEvent onValueChanged;

    private void Awake()
    {
        if (onValueChanged == null)
        {
            onValueChanged = new Toggle.ToggleEvent();
        }
    }

    [SerializeField]
    private bool m_IsOn = false;
    public bool IsOn
    {
        get { return m_IsOn; }
        set
        {
            if (m_IsOn != value)
            {
                m_IsOn = value;
                ResetControl(value);
                if (onValueChanged != null)
                {
                    onValueChanged.Invoke(value);
                }
            }
        }
    }

    [SerializeField]
    GameObject OnPart = null;

    [SerializeField]
    GameObject OffPart = null;

    public void ResetControl(bool value)
    {
        if (OnPart != null)
        {
            OnPart.SetActive(value);
        }

        if (OffPart != null)
        {
            OffPart.SetActive(!value);
        }
    }

#if UNITY_EDITOR

    bool tempValue = false;
    void OnGUI()
    {
        if (tempValue != IsOn)
        {
            tempValue = IsOn;
            ResetControl(IsOn);
        }
    }
#endif

    public void OnPointerClick(PointerEventData eventData)
    {
        IsOn = !IsOn;
    }


}
