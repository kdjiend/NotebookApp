NotebookApp/
├── NotebookApp.xcodeproj
├── NotebookApp/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├──
│   ├──
│   ├── ViewModels/
│   │   ├── NoteViewModel.swift
│   │   └── CategoryViewModel.swift
│   ├── Views/
│   │   ├── CategoryListView.swift
│   │   ├── NoteListView.swift
│   │   ├── NoteEditorView.swift
│   │   └── PasswordPromptView.swift
│   ├── Utils/
│   │   └── CryptoHelper.swift
│   └── Resources/
│       └── NotebookModel.xcdatamodeld
├
└── README.md






密钥派生 + 加密流程（Argon2id + AES-256-GCM）
用户输入密码

随机生成 salt（16 bytes）

使用 Argon2id 派生出 32 字节密钥（用于 AES-256）

使用 AES-256-GCM 加密内容，生成密文 + tag + iv

Core Data（元信息） + 二进制 Blob（加密内容）





Core Data 模型设计（初版）
Category
├── id: UUID
├── name: String
├── parent: Category?   // 多层结构
└── notes: [Note]

Note
├── id: UUID
├── title: String
├── createdAt: Date
├── updatedAt: Date
├── encryptedData: Data  // 加密后的内容 blob
├── salt: Data           // Argon2id 使用的 salt
├── nonce: Data          // AES-GCM IV
├── tag: Data            // GCM 认证标签
├── category: Category







先清理构建缓存 ⇧ + ⌘ + K
也可以在 Xcode 中  Product > Clean Build Folder

清理 ⇧ + ⌘ + G
~/Library/Containers/NotebookApp
如图倒数第二个：
<img width="208" alt="image" src="https://github.com/user-attachments/assets/7c3d9bdd-dee8-44d8-bc52-721de7cc141f" />





彻底删除缓存文件：
rm -rf ~/Library/Developer/Xcode/DerivedData
或者在 Xcode：
Window > Projects → 选择项目 → 点击 Delete 派生数据
然后重新编译。























