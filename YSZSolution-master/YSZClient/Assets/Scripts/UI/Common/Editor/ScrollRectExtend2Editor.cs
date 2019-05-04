using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.UI;

namespace UnityEditor.UI
{
    [CustomEditor(typeof(ScrollRectExtend2))]
    public class ScrollRectExtend2Editor : ScrollRectEditor
    {
        private ScrollRectExtend2 scrollRectExtend = null;

        private SerializedObject m_Object = null;

        private SerializedProperty m_OnClick = null;

        protected override void OnEnable()
        {
            scrollRectExtend = target as ScrollRectExtend2;
            if (scrollRectExtend == null)
                return;

            m_Object = new SerializedObject(target);
            m_OnClick = m_Object.FindProperty("onClick");
            base.OnEnable();
        }

        public override void OnInspectorGUI()
        {
            if (scrollRectExtend == null)
                return;            
            base.OnInspectorGUI();
            m_Object.Update();
            EditorGUILayout.PropertyField(m_OnClick, new GUIContent("On Click"));
            m_Object.ApplyModifiedProperties();
        }
    }
}