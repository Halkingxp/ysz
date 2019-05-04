using UnityEngine;
using UnityEngine.UI;
using UnityEditor;

/// <summary>
/// 批量修改UI字体脚本，脚本位于Endit文件夹
/// </summary>
public class ChangeFontWindow : EditorWindow
{
    //window菜单下
    [MenuItem("Tools/Change Font")]
    private static void ShowWindow()
    {
        EditorWindow.GetWindow<ChangeFontWindow>(true, "Tools/Change Font");        
        toFont = new Font("Arial");
    }

    //默认字体
    static Font toFont;
    //切换到的字体
    static Font toChangeFont;
    //字体类型
    FontStyle toFontStyle;
    //切换到的字体类型
    static FontStyle toChangeFontStyle;

    static bool isChangeFontSytle = false;

    private void OnGUI()
    {
        GUILayout.Space(10);
        GUILayout.Label("目标字体:");
        toFont = (Font)EditorGUILayout.ObjectField(toFont, typeof(Font), true, GUILayout.MinWidth(100f));
        toChangeFont = toFont;
        GUILayout.Space(10);
        GUILayout.Label("字体类型:");
        isChangeFontSytle = EditorGUILayout.Toggle("修改字体样式", isChangeFontSytle);
        toFontStyle = (FontStyle)EditorGUILayout.EnumPopup(toFontStyle, GUILayout.MinWidth(100f));
        toChangeFontStyle = toFontStyle;
        if (GUILayout.Button("确认修改"))
        {
            Change();
        }
    }

    public static void Change()
    {
        //获取所有UILabel组件
        if (Selection.objects == null || Selection.objects.Length == 0) return;
        Object[] labels = Selection.GetFiltered(typeof(Text), SelectionMode.Deep);
        foreach (Object item in labels)
        {
            Text label = (Text)item;
            label.font = toChangeFont;
            if (isChangeFontSytle)
            {
                label.fontStyle = toChangeFontStyle;
            }

            EditorUtility.SetDirty(item); //重要
        }
        Debug.Log("替换完成!");
    }
}