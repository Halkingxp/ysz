//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;
//using UnityEditor;
//using Common.Animation;

//[CustomEditor(typeof(AnimationControl), true)]
//public class AnimationControlEditor : Editor
//{
//    protected readonly GUILayoutOption m_LabelWidth = GUILayout.Width(110f);

//    private int removeIndex = -1;

//    private GUIContent debugBtn;

//    // 添加按钮文本
//    private GUIContent m_IconToolbarPlus;

//    //移除按钮文本
//    private GUIContent m_IconToolbarMinus;

//    public override void OnInspectorGUI()
//    {
//        GUILayout.Space(6f);
//        base.OnInspectorGUI();
//        DrawCommonProperties();
//    }

//    SerializedProperty animationPathList = null;

//    private void OnEnable()
//    {
//        animationPathList = serializedObject.FindProperty("m_AnimationPaths");


//        debugBtn = new GUIContent("Debug");
//        debugBtn.tooltip = "Debug values about the npc";

//        m_IconToolbarPlus = new GUIContent(EditorGUIUtility.IconContent("Toolbar Plus"));
//        m_IconToolbarPlus.tooltip = "Add a item with this list.";

//        m_IconToolbarMinus = new GUIContent(EditorGUIUtility.IconContent("Toolbar Minus"));
//        m_IconToolbarMinus.tooltip = "Remove a Item in this list.";
//    }

//    protected void DrawCommonProperties()
//    {
//        serializedObject.Update();
//        AnimationControl ani = target as AnimationControl;
//        GUI.changed = false;
//        EditorGUIUtility.labelWidth = 110f;

//        AnimationControl.PlayStyle style = (AnimationControl.PlayStyle)EditorGUILayout.EnumPopup("Play Style", ani.style);
//        GUILayout.Label(string.Format("动画路径信息:Count({0})", animationPathList.arraySize));
//        if (animationPathList.arraySize > 0)
//        {
//            for (int i = 0; i < animationPathList.arraySize; i++)
//            {
//                if (DrawHeader(string.Format("路径：[{0}]", i + 1)))
//                {
//                    BeginContents(false);
//                    GUILayout.BeginHorizontal();
//                    SerializedProperty animationPath = animationPathList.GetArrayElementAtIndex(i);
//                    // 备注信息
//                    SerializedProperty pathName = animationPath.FindPropertyRelative("PathName");
//                    EditorGUILayout.PropertyField(pathName, new GUIContent("动画名称:"));
//                    SerializedProperty relativeTrans = animationPath.FindPropertyRelative("HandleTransform");
//                    GUILayout.EndHorizontal();
//                    GUILayout.BeginHorizontal();
//                    EditorGUILayout.PropertyField(relativeTrans, new GUIContent("动画对象:"));
//                    GUILayout.EndHorizontal();

//                    // 绘制动画帧长度
//                    SerializedProperty animationFrames = animationPath.FindPropertyRelative("m_Frames");
//                    if (animationFrames.arraySize > 0)
//                    {
//                        for (int j = 0; j < animationFrames.arraySize; j++)
//                        {
//                            SerializedProperty animationFrame = animationFrames.GetArrayElementAtIndex(j);
//                             animationFrame.FindPropertyRelative("Time");
//                            GUILayout.BeginHorizontal();
//                            EditorGUILayout.PropertyField(relativeTrans, new GUIContent("动画对象:"));
//                            GUILayout.EndHorizontal();
//                        }
//                    }
                    

//                    EndContents();
//                }
//            }
//        }

//        EditorGUIUtility.labelWidth = 80f;
//        if (GUI.changed)
//        {
//            EditorUtility.SetDirty(target);
//        }
//        serializedObject.ApplyModifiedProperties();
//    }

//    void DrawAnimationPathList()
//    {
//        if (animationPathList.arraySize <= 0)
//        {
//            return;
//        }

//        for (int i = 0; i < animationPathList.arraySize; i++)
//        {
//            SerializedProperty frameList = animationPathList.GetArrayElementAtIndex(i);
//            DrawAnimationFrameList(frameList);
//        }
//    }

//    void DrawAnimationFrameList(SerializedProperty frameList)
//    {
//        if (frameList.arraySize <= 0)
//        {
//            return;
//        }

//        for (int i = 0; i < frameList.arraySize; i++)
//        {
//            SerializedProperty frame = animationPathList.GetArrayElementAtIndex(i);
//            DrawAniamtionFrame(frame);
//        }
//    }

//    void DrawAniamtionFrame(SerializedProperty frame)
//    {

//    }

//    public static void RegisterUndo(string name, params Object[] objects)
//    {
//        if (objects != null && objects.Length > 0)
//        {
//            UnityEditor.Undo.RecordObjects(objects, name);

//            foreach (Object obj in objects)
//            {
//                if (obj == null)
//                    continue;
//                EditorUtility.SetDirty(obj);
//            }
//        }
//    }

//    static bool mEndHorizontal = false;

//    /// <summary>
//    /// Begin drawing the content area.
//    /// </summary>

//    static public void BeginContents(bool minimalistic)
//    {
//        if (!minimalistic)
//        {
//            mEndHorizontal = true;
//            GUILayout.BeginHorizontal();
//            EditorGUILayout.BeginHorizontal("AS TextArea", GUILayout.MinHeight(10f));
//        }
//        else
//        {
//            mEndHorizontal = false;
//            EditorGUILayout.BeginHorizontal(GUILayout.MinHeight(10f));
//            GUILayout.Space(10f);
//        }
//        GUILayout.BeginVertical();
//        GUILayout.Space(2f);
//    }

//    /// <summary>
//    /// End drawing the content area.
//    /// </summary>

//    static public void EndContents()
//    {
//        GUILayout.Space(3f);
//        GUILayout.EndVertical();
//        EditorGUILayout.EndHorizontal();

//        if (mEndHorizontal)
//        {
//            GUILayout.Space(3f);
//            GUILayout.EndHorizontal();
//        }

//        GUILayout.Space(3f);
//    }

//    public static bool DrawHeader(string text)
//    {
//        return DrawHeader(text, text, false, false);
//    }

//    static public bool DrawHeader(string text, string key, bool forceOn, bool minimalistic)
//    {
//        bool state = EditorPrefs.GetBool(key, true);

//        if (!minimalistic) GUILayout.Space(3f);
//        if (!forceOn && !state) GUI.backgroundColor = new Color(0.8f, 0.8f, 0.8f);
//        GUILayout.BeginHorizontal();
//        GUI.changed = false;

//        if (minimalistic)
//        {
//            if (state) text = "\u25BC" + (char)0x200a + text;
//            else text = "\u25BA" + (char)0x200a + text;

//            GUILayout.BeginHorizontal();
//            GUI.contentColor = EditorGUIUtility.isProSkin ? new Color(1f, 1f, 1f, 0.7f) : new Color(0f, 0f, 0f, 0.7f);
//            if (!GUILayout.Toggle(true, text, "PreToolbar2", GUILayout.MinWidth(20f))) state = !state;
//            GUI.contentColor = Color.white;
//            GUILayout.EndHorizontal();
//        }
//        else
//        {
//            text = "<b><size=11>" + text + "</size></b>";
//            if (state) text = "\u25BC " + text;
//            else text = "\u25BA " + text;
//            if (!GUILayout.Toggle(true, text, "dragtab", GUILayout.MinWidth(20f))) state = !state;
//        }

//        if (GUI.changed) EditorPrefs.SetBool(key, state);

//        if (!minimalistic) GUILayout.Space(2f);
//        GUILayout.EndHorizontal();
//        GUI.backgroundColor = Color.white;
//        if (!forceOn && !state) GUILayout.Space(3f);
//        return state;
//    }
//}
