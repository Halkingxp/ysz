using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.UI;

namespace UnityEditor.UI
{
    [CustomEditor(typeof(ScrollRectExtend))]
    public class ScrollRectExtendEditor : ScrollRectEditor
    {
        private ScrollRectExtend scrollRectExtend = null;

        private SerializedObject m_Object = null;

        private SerializedProperty m_LeftArrowProperty = null;
        private SerializedProperty m_RightArrowProperty = null;
        private SerializedProperty m_DisplayItemCountProperty = null;

        protected override void OnEnable()
        {
            scrollRectExtend = target as ScrollRectExtend;
            if (scrollRectExtend == null)
                return;

            m_Object = new SerializedObject(target);

            m_LeftArrowProperty = m_Object.FindProperty("m_LeftArrow");
            m_RightArrowProperty = m_Object.FindProperty("m_RightArrow");
            m_DisplayItemCountProperty = m_Object.FindProperty("m_DisplayItemCount");
            base.OnEnable();
        }

        public override void OnInspectorGUI()
        {
            if (scrollRectExtend == null)
                return;
            m_Object.Update();         
            EditorGUILayout.PropertyField(m_LeftArrowProperty, new GUIContent("Left Arrow"));
            EditorGUILayout.ObjectField(m_RightArrowProperty, new GUIContent("Right Arrow"));
            m_DisplayItemCountProperty.intValue = EditorGUILayout.IntField(new GUIContent("Display Item Count"), m_DisplayItemCountProperty.intValue);
            m_Object.ApplyModifiedProperties();
            base.OnInspectorGUI();            
        }
    }
}