using UnityEngine;
using System.Collections;
using UnityEditor;

public class ArtistFont : MonoBehaviour
{
    public static void BatchCreateArtistFont()
    {
        string dirName = "";
        string fntname = EditorUtils.SelectObjectPathInfo(ref dirName).Split('.')[0];
        Debug.Log(fntname);
        Debug.Log(dirName);

        string fntFileName = dirName + fntname + ".fnt";

        Font CustomFont = new Font();
        {
            AssetDatabase.CreateAsset(CustomFont, dirName + fntname + ".fontsettings");
            AssetDatabase.SaveAssets();
        }

        TextAsset BMFontText = null;
        {
            BMFontText = AssetDatabase.LoadAssetAtPath(fntFileName, typeof(TextAsset)) as TextAsset;
        }

        BMFont mbFont = new BMFont();
        BMFontReader.Load(mbFont, BMFontText.name, BMFontText.bytes);  // 借用NGUI封装的读取类
        CharacterInfo[] characterInfo = new CharacterInfo[mbFont.glyphs.Count];
        for (int i = 0; i < mbFont.glyphs.Count; i++)
        {
            BMGlyph bmInfo = mbFont.glyphs[i];
            CharacterInfo info = new CharacterInfo();
            info.index = bmInfo.index;
            info.uvTopLeft = new Vector2((float)bmInfo.x / (float)mbFont.texWidth, (float)(bmInfo.y + bmInfo.height) / (float)mbFont.texHeight);
            info.uvTopRight = new Vector2((float)(bmInfo.x + bmInfo.width) / (float)mbFont.texWidth, (float)(bmInfo.y + bmInfo.height) / (float)mbFont.texHeight);
            info.uvBottomLeft = new Vector2((float)bmInfo.x / (float)mbFont.texWidth, (float)bmInfo.y / (float)mbFont.texHeight);
            info.uvBottomRight = new Vector2((float)(bmInfo.x + bmInfo.width) / (float)mbFont.texWidth, (float)(bmInfo.y) / (float)mbFont.texHeight);

            info.minX = bmInfo.offsetX;
            info.minY = bmInfo.offsetY;
            info.maxX = bmInfo.width;
            info.maxY = bmInfo.height;
            info.advance = bmInfo.advance;
            characterInfo[i] = info;
        }
        CustomFont.characterInfo = characterInfo;


        string textureFilename = dirName + mbFont.spriteName + ".png";
        Material mat = null;
        {
            Shader shader = Shader.Find("UI/Unlit/Text");
            mat = new Material(shader);
            Texture tex = AssetDatabase.LoadAssetAtPath(textureFilename, typeof(Texture)) as Texture;
            mat.SetTexture("_MainTex", tex);
            AssetDatabase.CreateAsset(mat, dirName + fntname + ".mat");
            AssetDatabase.SaveAssets();
        }
        CustomFont.material = mat;
    }
}
