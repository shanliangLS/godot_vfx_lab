using UnityEditor;
using UnityEngine;

// PARADOX Novissime - Unity importer.
// Every model under a "ParadoxNovissime" folder gets ONE shared material (palette + glow), so recolouring
// T_Novissime_Palette.png / T_Novissime_Emission.png updates the whole pack. Palette textures import crisp (Point).
public class NovissimeImporter : AssetPostprocessor
{
    const string Root = "Assets/ParadoxNovissime";
    const string MatPath = Root + "/Materials/M_Novissime.mat";

    void OnPreprocessTexture()
    {
        if (!assetPath.Contains("/ParadoxNovissime/")) return;
        var ti = (TextureImporter)assetImporter;
        ti.filterMode = FilterMode.Point;
        ti.mipmapEnabled = false;
        ti.textureCompression = TextureImporterCompression.Uncompressed;
    }

    void OnPreprocessModel()
    {
        if (!assetPath.Contains("/ParadoxNovissime/")) return;
        var mi = (ModelImporter)assetImporter;
        mi.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
        mi.materialLocation = ModelImporterMaterialLocation.InPrefab;
    }

    Material OnAssignMaterialModel(Material material, Renderer renderer)
    {
        if (!assetPath.Contains("/ParadoxNovissime/")) return null;
        var mat = AssetDatabase.LoadAssetAtPath<Material>(MatPath);
        if (mat == null)
        {
            // never create assets during import: create the material right after, then reimport the models
            EditorApplication.delayCall += () =>
            {
                SharedMaterial();
                AssetDatabase.ImportAsset(Root + "/FBX", ImportAssetOptions.ImportRecursive | ImportAssetOptions.ForceUpdate);
            };
        }
        return mat;
    }

    public static Material SharedMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>(MatPath);
        if (mat != null)
        {
            // first import may run before the textures exist: fill them in once they do
            if (mat.GetTexture("_EmissionMap") == null)
            {
                bool u = mat.shader.name.StartsWith("Universal");
                mat.SetTexture(u ? "_BaseMap" : "_MainTex", AssetDatabase.LoadAssetAtPath<Texture2D>(Root + "/Textures/T_Novissime_Palette.png"));
                mat.SetTexture("_EmissionMap", AssetDatabase.LoadAssetAtPath<Texture2D>(Root + "/Textures/T_Novissime_Emission.png"));
                EditorUtility.SetDirty(mat);
            }
            return mat;
        }
        System.IO.Directory.CreateDirectory(Root + "/Materials");
        var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
        mat = new Material(shader) { name = "M_Novissime" };
        var pal = AssetDatabase.LoadAssetAtPath<Texture2D>(Root + "/Textures/T_Novissime_Palette.png");
        var emi = AssetDatabase.LoadAssetAtPath<Texture2D>(Root + "/Textures/T_Novissime_Emission.png");
        bool urp = shader.name.StartsWith("Universal");
        mat.SetTexture(urp ? "_BaseMap" : "_MainTex", pal);
        mat.SetTexture("_EmissionMap", emi);
        mat.SetColor("_EmissionColor", Color.white * 1.6f);
        mat.EnableKeyword("_EMISSION");
        mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
        mat.SetFloat(urp ? "_Smoothness" : "_Glossiness", 0.55f);
        AssetDatabase.CreateAsset(mat, MatPath);
        return mat;
    }
}
