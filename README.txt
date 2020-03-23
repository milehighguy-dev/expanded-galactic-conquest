This is the repository for the expanded galactic conquest mod for Star Wars Battlefront 2 (2005). It is still a work in progress. The goal
for the initial release is to have the galactic conquest work just like it does in the base game except with multiple factions instead of
just 2. Long term the goal is to add some elements from Star Wars Empire at War, Total War, and Mount and Blade games.

Currently, this mod requires another mod: "Star Wars Battlefront 2: Remaster" to be installed. The data folder of this mod is called
"data_GDB" (it seems I messed up when uploading the repository). munge the map like normal, and in the addon "GDB" folder you must create a
folder called "scripts". munge the shell.lvl for the data_GDB project and move it to that folder in addon. Rename it to 
"GDB_interface_script.lvl". 
Now when you launch the game for the first time you will have to go into the Remaster settings and detect the GDB project (only need to do 
once). You should see the button for "Galactic Conquest Debug" to launch the mod.

Currently it crashes after 10 or so turns. It has something to do with ScriptCB_PushScreen() I think. Hopefully that bug will be solved by
collaboration. After the mystery bugs are solved it will be mostly straightforward to finish the mod because the other major hurdles have
been solved.
