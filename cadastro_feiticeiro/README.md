# Cadastro de Feiticeiros - Escola Jujutsu

## 1. Gerar as pastas de plataforma (android, ios, web...)
Dentro desta pasta, rode:

    flutter create --org com.jujutsu --project-name cadastro_feiticeiros .
    flutter pub get

(O `flutter create .` NÃO sobrescreve lib/main.dart nem pubspec.yaml já existentes.)

## 2. Configurar o Firebase
1. Crie um projeto no Firebase Console.
2. Authentication > Sign-in method > ative **Google**.
3. Firestore Database > crie o banco e cole o conteúdo de `firestore.rules` na aba Regras.
4. Conecte o app (escolha UMA opção):

   **Opção A (recomendada):**

       dart pub global activate flutterfire_cli
       flutterfire configure

   Depois, em `lib/main.dart`, descomente `import 'firebase_options.dart';`
   e `options: DefaultFirebaseOptions.currentPlatform`.

   **Opção B (somente Android):** baixe o `google-services.json` e coloque em
   `android/app/`. Adicione também o plugin do Google Services no Gradle.

5. Android: adicione o SHA-1 do seu keystore em Configurações do projeto > seu app Android
   (necessário para o login com Google):

       cd android && ./gradlew signingReport

   Se estiver usando Android, garanta `minSdkVersion 23` em `android/app/build.gradle`.

## 3. Rodar

    flutter run

## Estrutura do Firestore
Coleção `missoes`, cada documento:
- titulo (string)
- grau (number)
- concluida (bool)
- usuarioId (string) = FirebaseAuth.instance.currentUser!.uid

O app filtra com `.where('usuarioId', isEqualTo: uid)` e as regras em
`firestore.rules` garantem que ninguém leia missões de outro feiticeiro.
