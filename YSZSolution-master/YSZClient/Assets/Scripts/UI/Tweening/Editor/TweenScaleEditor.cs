using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TweenScale))]
public class TweenScaleEditor : UITweenerEditor
{
    public override void OnInspectorGUI()
    {
        GUILayout.Space(6f);
        EditorGUIUtility.labelWidth = 120f;
        TweenScale tw = target as TweenScale;
        GUI.changed = false;

        Vector3 from = EditorGUILayout.Vector3Field("From", tw.from);
        Vector3 to = EditorGUILayout.Vector3Field("To", tw.to);

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
