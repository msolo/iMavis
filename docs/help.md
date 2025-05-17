# Mavis Help

Mavis has a few features designed to make composing messages easier. This application was designed and built for a specific person who was a very competent typist, but who also possessed a distinct antipathy for computing technology.

The default settings and capabilities were strongly influenced by her needs and abilities as well as my best guesses on how to make living with this technology easier for her. There are many possible ways to modify and improve the software for specific needs.

# 0. Text to speech

You can be lazy. Text to speech does not care about capitalization and usually doesn't care much about homophones either - their, they're and there are all pronounced about the same.

Sometimes there are subtle differences with some punctuation, like hyphens and commas. Unfortunately, right now most of the voices don't recognize the difference between `"Hello."`, `"Hello?"` and `"Hello!"` -- that's a current limitation of the Apple Speech synthesizer.

If there is a persistent problem, there are ways to tweak pronunciation inside the voice synthesizer. See the section on **Pronunciations**.

# 1. Keyboard Navigation

You shouldn’t need to use menus with Mavis most of the time. Hunting through menus takes your fingers off the home row and ends up slowing you down.

Whatever you type in the composition text will be spoken when you press **Return**.

The last 10 phrases are remembered and you can quickly access them using the **Command** key ⌘ and up ↑ and down ↓ arrow keys.

Swiping items in the history list will allow you to delete a history item.

All the standard Mac keyboard navigation tricks work.

⌘← and ⌘→ (**Command** with the left or right arrow keys) will let you skip to the beginning or end of the composition.

⌥← and ⌥→ (**Option** with the left or right arrow keys) will let you skip backward and forward word by word.

⌥ Delete (Option with Delete) will delete a "word" backwards.

# 2. History

If you need to quickly repeat the last message, **Command** key and Return ⌘-Return will respeak the last message.

Alternatively, **Command** key and up arrow ⌘↑ will recall the last message in the history. **Return** will speak it aloud.

# 3. Tab Completion

When you press the **Tab** key, Mavis will suggest a useful word or phrase that can be quickly inserted into the message based on the words already typed, the dictionary and a configurable list of phrases.

When the completion menu is showing, you can navigate the completion choices with the up ↑ and down ↓ arrow keys.

The first press of the **Return** key will accept the current highlighted completion, and a second press of **Return** will speak the text aloud.

The **Escape** or **Delete** keys (**esc** on the top left of your keyboard), cancels the completion menu and selects nothing.

# 4. FaceTime

If you are on a FaceTime call, Mavis is ready to help and you can speak with both your voice and the synthesizer.

# 5. Adjusting The Font Size

Inside the **Settings** sheet, you can adjust the size of the font in the compose box.

# 6. Speak Sentences Automatically

Mavis can (and does by default) automatically speak each sentence while you type. Technically, it speaks every time the space bar is pressed and the previous sentence ends with a period, exclamation point or question mark.

There is a preference for this in the **Chat** menu - **Speak Sentences Automatically**.

# 7. Excruciating Details about Tab Completion and Configuration

This will help you understand what Mavis does when you hit **Tab.**

If you press type "z" and then a **Tab**, Mavis will show you all the things you can say with your original soundbites or phrase list.

You can edit the phrase list by going to the **Settings** and selecting **Edit Phrases...**.

If there is a bit of text and **Completer Mode** (see below) is turned on, it will try to fix typos, spelling errors and simple grammatical issues in one shot.


# 8. Pronunciations

Under the **Settings** menu select **Edit Pronunciations...**.

Each line of this file corrects the pronunciation of a word.

For example, this line below tells the voice synthesizer that "Ez" - should be pronounced like "Ezz" - short for Ezra - instead of like E-Z as in "easy."

```
Ez|Ezz
```

This can't solve homographs (**read** 'em and weep versus **read** that yesterday), but if that's a problem, let me know. It's not unsolvable, just harder.

There is no requirement that pronunciations correction have much to with the orthography. For instance, you can also do:

```
pepsi|coke
```

# 9. Soundbites

Soundbites takes voice bank recordings and lets you play them back exactly as recorded. The catch is that what you type into Mavis must exactly match the phrase.

If you don't remember the exact phrase, type "z" and hit the **Tab** key - that will bring up all known phrases. You can scroll through them or type a few characters to show a limited set of matching results.

You can disable **Soundbites** in the **Chat** menu, same as all the other features.

> NOTE: Soundbites do not play over Facetime or phone calls.

# 10. Noisy Typing

Noisy Typing plays an audible click sound when you type into Mavis. This plays over the speakers to let people know that you are typing "conversationally", not beavering away on some other distraction on your device.

You can disable **Noisy Typing** in the **Chat** menu.

> NOTE: Noisy typing sounds do not play over Facetime or phone calls.

# 11. Ring Bell

The Ring Bell button (or **Command-R** or **⌘R**) plays a ringing bell sound to get someone's attention, without removing what you've already typed into Mavis.

The Double Bell button (or **Command-Shift-R** or **⌘⇧R**) is a litte louder and more aggressive.

The bell sounds were selected to be pleasant, but still capable of getting attention.

# 12. Settings

Adjusting the voice and volumes for various features is possible via the **Settings** panel.

## Voice Controls

Choose your voice and set it's basic speaking properties.

## Sound Effects

Adjust the volume of various sound effect.

## Input

Adjust how keyboard input is handled.

Minimum Return Key Delay is the to help prevent accidental double presses of the return key.

## Display

Adjust font sizes and how long the display will stay awake when using the app to speak.

## Configuration

**Edit Pronunciations** and **Edit Phrases** should be self-explanatory.

**Import File** allows you to import several different special files that you have saved on your device.

### soundbites.zip

This zip archive can contain any number of sound files that are in the `.wav` or `.m4a` formats. The importer uses the name of the each file in the zip archive as the exact text to use when matching a soundbite.

For instance `Hello.wav` and `Hello!.wav` could be distinct entries. Typing "hello" would only match the first. "hello!" would only match the second.

## Export

This lets you send any logged chats via Apple's sharing mechanisms to do some analysis. This mechanism was used to help train early versions of the text correction engine and collect data about patterns of typos or other systematic typing errors.

For this to be useful, you have to enable chat logging, which is obviously disabled by default to preserve privacy.

# 13. Completer Mode

This uses a small neural network to try to clean keyboard input with typos, spelling and grammatical mistakes before sending it to the voice synthesizer.

Right now it's takes about a second, but it will give you up to 5 options of corrections. Studies show that is has a reasonble chance of fixing things, and can likely be improved over time.

To turn this off, under the **Chat** menu, inside the **Completer Mode**.

## Show Completions Automatically

If the built-in spell/grammar checker detects you have an error, Mavis can automatically trigger the completer when you try to speak something that likely won't make perfect sense. This is useful as long as the builtin dictionary match the words you normally use. This is on by default, but can be turned off via the **Show Completions Automatically** item in the **Chat** menu.
