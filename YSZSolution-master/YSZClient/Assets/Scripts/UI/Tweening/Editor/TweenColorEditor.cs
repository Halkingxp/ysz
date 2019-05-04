﻿using UnityEngine;
using UnityEditor;

public class TweenColorEditor : UITweenerEditor
{
    public override void OnInspectorGUI()
    {
        GUILayout.Space(6f);
        EditorGUIUtility.labelWidth = 120f;
        TweenColor tw = target as TweenColor;
        GUI.changed = false;

        Color from = EditorGUILayout.ColorField("From", tw.from);
        Color to = EditorGUILayout.ColorField("To", tw.to);

        if (GUI.changed)
        {
            RegisterUndo("Tween Change", tw);
            tw.from = from;
            tw.to = to;
            EditorUtility.SetDirty(tw);
        }

        DrawCommonProperties();
    }
}

