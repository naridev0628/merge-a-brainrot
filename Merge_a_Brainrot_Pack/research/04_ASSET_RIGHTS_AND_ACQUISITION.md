# Asset rights and acquisition

Status: no third-party production assets selected; all six roster rows are planned original placeholders. No claim is made that a proposed name has legal clearance.

Creator Store terms govern licensed use of acquired assets in Studio/Roblox experiences. Acquisition does not make this team the original author. Record the actual creator, listing and applicable permission/terms when acquiring an asset. [Creator Store Terms](https://en.help.roblox.com/hc/en-us/articles/21308223046932-Creator-Store-Terms), [Creator Store documentation](https://create.roblox.com/docs/production/creator-store).

Restricted platform assets need appropriate experience access; access status and underlying creative rights are separate questions. Record dependencies and check the target experience. [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy).

Imported models can contain malicious scripts or unexpected dependencies. Inspect descendants and scripts before use; avoid obfuscated code, numerical external requires and unrelated data/network behaviour. Do not execute archive code as part of inspection. [Third-party asset vulnerabilities](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities).

## Practical route

1. Implement the six original primitive concepts in `assets/ORIGINAL_CHARACTER_ROSTER.csv`; leave asset IDs blank.
2. If replacing a placeholder, obtain team-created art, a commission with recorded appropriate permission, or an authorized asset with documented terms and provenance.
3. Fill `assets/ASSET_MANIFEST.csv`: creator, source/permission evidence, permitted scope, credit, dependencies, script review, target access and review status.
4. Keep unknown entries as `needs_review` and continue using placeholders. A free/public listing or familiar meme name alone does not establish rights.
5. Test the approved dependency in an isolated place and verify the target experience can load it before connecting the model registry.

Familiar names such as the user's Tong Tong/cappuccino examples are conceptual examples, not an instruction or license to import Steal a Brainrot models. Names, model files, textures, audio, logos and recordings may have distinct provenance. Do not rip proprietary game content, trace distinctive character meshes from renders, reuse known voice clips or call acquired assets “our original models.”

`reference/` holds observation notes and evidence pointers; `assets/` holds actual production approvals. Legacy screenshots, guide images, marketing art and video thumbnails are not repackaged as new game assets. Source archive possession and “official” folder names do not establish a production or redistribution license. This is a project workflow, not a legal clearance opinion.
