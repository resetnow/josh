  $ . ${TESTDIR}/setup_test_env.sh
  $ cd ${TESTTMP}


  $ git clone -q http://localhost:8001/real_repo.git
  warning: You appear to have cloned an empty repository.

  $ curl -s http://localhost:8002/version
  Version: * (glob)

  $ cd real_repo

  $ git status
  On branch master
  
  No commits yet
  
  nothing to commit (create/copy files and use "git add" to track)

  $ git checkout -b master
  Switched to a new branch 'master'


  $ echo content1 > file1 1> /dev/null
  $ git add .
  $ git commit -m "initial" 1> /dev/null

  $ git checkout -b new1
  Switched to a new branch 'new1'
  $ echo content > newfile1 1> /dev/null
  $ git add .
  $ git commit -m "add newfile1" 1> /dev/null

  $ git checkout master 1> /dev/null
  Switched to branch 'master'
  $ echo content > newfile_master 1> /dev/null
  $ git add .
  $ git commit -m "newfile master" 1> /dev/null

  $ git merge new1 --no-ff
  Merge made by the 'recursive' strategy.
   newfile1 | 0
   1 file changed, 0 insertions(+), 0 deletions(-)
   create mode 100644 newfile1


  $ mkdir -p sub1/subsub
  $ echo contents1 > sub1/subsub/file1
  $ git add .
  $ git commit -m "add file1" 1> /dev/null

  $ mkdir sub2
  $ echo contents1 > sub2/file2
  $ git add sub2
  $ git commit -m "add file2" 1> /dev/null

  $ mkdir ws
  $ cat > ws/workspace.josh <<EOF
  > a/b = :/sub2
  > c = :/sub1
  > EOF

  $ git add ws
  $ git commit -m "add workspace" 1> /dev/null

  $ mkdir sub3
  $ echo contents3 > sub3/file3
  $ git add sub3
  $ git commit -m "add file3" 1> /dev/null

  $ cat > ws/workspace.josh <<EOF
  > a/b = :/sub2
  > c = :/sub1
  > d = :/sub3
  > EOF

  $ git add ws
  $ git commit -m "mod workspace" 1> /dev/null

  $ git log --graph --pretty=%s
  * mod workspace
  * add file3
  * add workspace
  * add file2
  * add file1
  *   Merge branch 'new1'
  |\  
  | * add newfile1
  * | newfile master
  |/  
  * initial


  $ git push
  To http://localhost:8001/real_repo.git
   * [new branch]      master -> master

  $ cd ${TESTTMP}

  $ git clone -q http://localhost:8002/real_repo.git:workspace=ws:prefix=pre:/pre.git ws
  $ cd ws
  $ tree
  .
  |-- a
  |   `-- b
  |       `-- file2
  |-- c
  |   `-- subsub
  |       `-- file1
  |-- d
  |   `-- file3
  `-- workspace.josh
  
  5 directories, 4 files

  $ git log --graph --pretty=%s
  *   mod workspace
  |\  
  | * add file3
  * add workspace
  * add file2
  * add file1

  $ git checkout HEAD~1 1> /dev/null
  Note: switching to 'HEAD~1'.
  
  You are in 'detached HEAD' state. You can look around, make experimental
  changes and commit them, and you can discard any commits you make in this
  state without impacting any branches by switching back to a branch.
  
  If you want to create a new branch to retain commits you create, you may
  do so (now or later) by using -c with the switch command. Example:
  
    git switch -c <new-branch-name>
  
  Or undo this operation with:
  
    git switch -
  
  Turn off this advice by setting config variable advice.detachedHead to false
  
  HEAD is now at * add workspace (glob)
  $ tree
  .
  |-- a
  |   `-- b
  |       `-- file2
  |-- c
  |   `-- subsub
  |       `-- file1
  `-- workspace.josh
  
  4 directories, 3 files

  $ git checkout HEAD~1 1> /dev/null
  Previous HEAD position was * add workspace (glob)
  HEAD is now at * add file2 (glob)
  $ tree
  .
  |-- a
  |   `-- b
  |       `-- file2
  `-- c
      `-- subsub
          `-- file1
  
  4 directories, 2 files

  $ git checkout master 1> /dev/null
  Previous HEAD position was * add file2 (glob)
  Switched to branch 'master'

  $ echo newfile_1_contents > c/subsub/newfile_1
  $ git rm c/subsub/file1
  rm 'c/subsub/file1'
  $ echo newfile_2_contents > a/b/newfile_2
  $ echo ws_file_contents > ws_file

  $ git add .

  $ git commit -m "add in filter" 1> /dev/null

  $ git push
  remote: josh-proxy        
  remote: response from upstream:        
  remote:  To http://localhost:8001/real_repo.git        
  remote:    *..*  JOSH_PUSH -> master         (glob)
  remote: 
  remote: 
  To http://localhost:8002/real_repo.git:workspace=ws:prefix=pre:/pre.git
     *..*  master -> master (glob)

  $ cat > workspace.josh <<EOF
  > a/b = :/sub2
  > c = :/sub1
  > w = :/sub3
  > EOF

  $ git add .
  $ git commit -m "try to modify ws" 1> /dev/null

  $ git push 2>&1 >/dev/null | sed -e 's/[ ]*$//g'
  remote: josh-proxy
  remote: response from upstream:
  remote:  To http://localhost:8001/real_repo.git
  remote:    *..*  JOSH_PUSH -> master* (glob)
  remote: REWRITE(* -> *) (glob)
  remote:
  remote:
  To http://localhost:8002/real_repo.git:workspace=ws:prefix=pre:/pre.git
     *..*  master -> master* (glob)
  $ curl -s http://localhost:8002/flush
  Flushed credential cache
  $ git pull --rebase 2> /dev/null

Note that d/ is still in the tree but now it is not overlayed
  $ tree
  .
  |-- a
  |   `-- b
  |       |-- file2
  |       `-- newfile_2
  |-- c
  |   `-- subsub
  |       `-- newfile_1
  |-- d
  |   `-- file3
  |-- w
  |   `-- file3
  |-- workspace.josh
  `-- ws_file
  
  6 directories, 7 files



  $ cd ${TESTTMP}/real_repo

  $ curl -s http://localhost:8002/flush
  Flushed credential cache
  $ git pull --rebase 1> /dev/null
  From http://localhost:8001/real_repo
     *..*  master     -> origin/master (glob)

  $ git clean -ffdx 1> /dev/null

Note that ws/d/ is now present in the ws
  $ tree
  .
  |-- file1
  |-- newfile1
  |-- newfile_master
  |-- sub1
  |   `-- subsub
  |       `-- newfile_1
  |-- sub2
  |   |-- file2
  |   `-- newfile_2
  |-- sub3
  |   `-- file3
  `-- ws
      |-- d
      |   `-- file3
      |-- workspace.josh
      `-- ws_file
  
  6 directories, 10 files
  $ git log --graph --pretty=%s
  * try to modify ws
  * add in filter
  * mod workspace
  * add file3
  * add workspace
  * add file2
  * add file1
  *   Merge branch 'new1'
  |\  
  | * add newfile1
  * | newfile master
  |/  
  * initial

  $ cat sub1/subsub/file1
  cat: sub1/subsub/file1: No such file or directory
  [1]

  $ git checkout HEAD~1 1> /dev/null
  Note: switching to 'HEAD~1'.
  
  You are in 'detached HEAD' state. You can look around, make experimental
  changes and commit them, and you can discard any commits you make in this
  state without impacting any branches by switching back to a branch.
  
  If you want to create a new branch to retain commits you create, you may
  do so (now or later) by using -c with the switch command. Example:
  
    git switch -c <new-branch-name>
  
  Or undo this operation with:
  
    git switch -
  
  Turn off this advice by setting config variable advice.detachedHead to false
  
  HEAD is now at * add in filter (glob)
  $ git clean -ffdx 1> /dev/null
  $ tree
  .
  |-- file1
  |-- newfile1
  |-- newfile_master
  |-- sub1
  |   `-- subsub
  |       `-- newfile_1
  |-- sub2
  |   |-- file2
  |   `-- newfile_2
  |-- sub3
  |   `-- file3
  `-- ws
      |-- workspace.josh
      `-- ws_file
  
  5 directories, 9 files

  $ git checkout HEAD~1 1> /dev/null
  Previous HEAD position was * add in filter (glob)
  HEAD is now at * mod workspace (glob)
  $ git clean -ffdx 1> /dev/null
  $ tree
  .
  |-- file1
  |-- newfile1
  |-- newfile_master
  |-- sub1
  |   `-- subsub
  |       `-- file1
  |-- sub2
  |   `-- file2
  |-- sub3
  |   `-- file3
  `-- ws
      `-- workspace.josh
  
  5 directories, 7 files


  $ bash ${TESTDIR}/destroy_test_env.sh
  "real_repo.git" = [
      ':/sub1',
      ':/sub1/subsub',
      ':/sub2',
      ':/sub3',
      ':/ws',
      ':/ws/d',
      ':workspace=ws',
  ]
  refs
  |-- heads
  |-- josh
  |   |-- filtered
  |   |   `-- real_repo.git
  |   |       |-- %3A%2Fsub1
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3A%2Fsub1%2Fsubsub
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3A%2Fsub2
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3A%2Fsub3
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3A%2Fws
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3A%2Fws%2Fd
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       |-- %3Aworkspace=ws
  |   |       |   `-- heads
  |   |       |       `-- master
  |   |       `-- %3Aworkspace=ws%3Aprefix=pre%3A%2Fpre
  |   |           `-- heads
  |   |               `-- master
  |   |-- rewrites
  |   |   `-- real_repo.git
  |   |       `-- r_* (glob)
  |   `-- upstream
  |       `-- real_repo.git
  |           `-- refs
  |               `-- heads
  |                   `-- master
  |-- namespaces
  `-- tags
  
  28 directories, 10 files

$ cat ${TESTTMP}/josh-proxy.out | grep VIEW
