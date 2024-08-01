:- ensure_loaded(lib/controller_freak/controller_freak)
   ,ensure_loaded(lib/grid_master/data/environments/basic_environment/maze_generator)
   ,ensure_loaded(lib/grid_master/src/map_display)
   ,ensure_loaded(lib/grid_master/src/action_generator)
   ,ensure_loaded(lib/grid_master/src/map)
   ,ensure_loaded(lib/controller_freak/executors)
   ,ensure_loaded(lib/grid_master/data/environments/basic_environment/basic_environment)
   ,configuration:experiment_file(P,_M)
   ,ensure_loaded(P)
   ,ensure_loaded(test_scripts).

% Uncomment before running experiments to generate actions for MaGe
% and Dungeon maps. write_primitives/0 will take a while to generate all
% the actions for the 100 MaGe maps (and 10 dungon maps) but it only
% needs to be run once.
%:-action_generator:write_primitives.

:- use_module(lib/grid_master/grid_master_configuration)
  ,retract(grid_master_configuration:action_representation(_))
  ,assert(grid_master_configuration:action_representation(controller_sequences)).


%!      mage_maps(?Maps) is semidet.
%
%       Number of MaGe maps to solve.
%
%mage_maps(100).
mage_maps(1).


%!      dungeon_maps(?Maps) is semidet.
%
%       Number of dungeon maps to solve.
%
%dungeon_maps(10).
dungeon_maps(2).


%!      dungeon_instances(?Instances) is semidet.
%
%       Number of times to solve each dungon map.
%
%dungeon_instances(50).
dungeon_instances(1).


%!      seek_time_limit(?Limit) is semidet.
%
%       Time limit for seeking experiments.
%
seek_time_limit(300).


%!      debug_experiment(?Experiment,?Debug) is det.
%
%       Whether to visualise an Experiment while running, or not.
%
debug_experiment('1b',false):- !.
debug_experiment('2a',false):- !.
debug_experiment('2b',false):- !.
debug_experiment('2c',false):- !.
debug_experiment('2d',false):- !.
debug_experiment(_,false).


%!      memory_limites(?Experiment,?Stack,?Table) is det.
%
%       Stack and Table RAM limits for an Experiment.
%
memory_limits('1b',2_147_483_648,17_179_869_184):- !.
%memory_limits('1b',2_147_483_648,51_539_607_552):- !.
memory_limits(_,2_147_483_648,2_147_483_648).


:- nodebug(_).
%:- debug(trace_map_solver).
%:- debug(test_instance).
%:- debug(trace_mage_maps).
%:- debug(solve_dungeon_maps).
%:- debug(trace_path).
%:- debug(write_mage_maps).
%:- debug(test_instance).
%:- debug(solve).


run_experiments:-
        experiment_1b
        ,experiment_2a
        ,experiment_2b
        ,experiment_2d
        % Takes long, leave last.
        ,experiment_2c.


%!      experiment_1b is det.
%
%       Solve All dungeon maps, each 100 times.
%
experiment_1b:-
        dungeon_instances(K)
        ,debug_experiment('1b',Deb)
        ,memory_limits('1b',SL,TL)
        ,abolish_all_tables
        ,protocol('experiment_1b.log')
        ,set_memory_limits(SL,TL)
        ,debug(solve_dungeon_maps)
        ,solve_all_dungeon_maps(K,Rs,M,Deb)
        ,format('Solved ~w Dungeon maps. Mean number of steps: ~2f',[Rs,M])
        ,flush_output
        ,nodebug(solve_dungeon_maps)
        ,noprotocol.


%!      experiment_2a is det.
%
%       Solve 100 100 x 100 MaGe maps with an FSC.
%
%       Uses the backtracking executor.
%
experiment_2a:-
        abolish_all_tables
        ,seek_with_executor('2a',backtracking,mage,'experiment_2a.log').

%!      experiment_2b is det.
%
%       Solve 100 100 x 100 MaGe maps with an FSC.
%
%       Uses the revesing executor.
%
experiment_2b:-
        abolish_all_tables
        ,seek_with_executor('2b',reversing,mage,'experiment_2b.log').

%!      experiment_2c is det.
%
%       Solve 50 Dungeon maps with an FSC
%
%       Uses the backtracking_slam executor.
%
experiment_2c:-
        abolish_all_tables
        ,seek_with_executor('2c',backtracking_slam,dungeon,'experiment_2c.log').

%!      experiment_2c is det.
%
%       Solve 50 Dungeon maps with an FSC
%
%       Uses the reversing_slam executor.
%
experiment_2d:-
        abolish_all_tables
        ,seek_with_executor('2d',reversing_slam,dungeon,'experiment_2d.log').


%!      seek_with_executor(+Id,+Executor,+MapType,+Protocol) is det.
%
%       Search for a target on a map with the given Executor.
%
%       Id is the identifier of the experiment to run: 1b, 2a, 2b, 2c,
%       or 2d.
%
%       Executor is the name of a known executor: backtracking,
%       reversing, backtracking_slam or reversing_slam.
%
%       MapType is one of: mage, dungeon, denoting what kind of map is
%       to be solved.
%
%       Protocol is the filename of a log file to save results to, with
%       protocol/1.
%
seek_with_executor(Id,E_,T,L):-
        mage_maps(K)
        ,dungeon_maps(J)
        ,dungeon_instances(N)
        ,debug_experiment(Id,Deb)
        ,format('Starting experiment_~w~n',[Id])
        ,S = (controller_freak_configuration:executor(E)
            ,retract(controller_freak_configuration:executor(E))
            ,assert(controller_freak_configuration:executor(E_))
            ,protocol(L)
            ,debug(seek_dungeon_maps)
            ,debug(seek_mage_maps)
             )
        ,G = ((   T == dungeon
              ->  findall(I
                         ,between(1,J,I)
                         ,Is)
                 ,T_ = 'Dungeon'
                 ,seek_dungeon_maps(Is,N,Rs,M,Deb)
              ;   T = mage
              ->  findall(I
                         ,between(1,K,I)
                         ,Is)
                 ,T_ = 'MaGe'
                 ,seek_hard_coded_mage_maps(Is,Rs,M,Deb)
              )
             ,format('Solved ~w ~w maps with ~w executor. Mean number of steps: ~2f'
                    ,[Rs,T_,E_,M])
             ,flush_output
             )
        ,C = (retract(controller_freak_configuration:executor(E_))
             ,assert(controller_freak_configuration:executor(E))
             ,noprotocol
             ,nodebug(seek_dungeon_maps)
             ,nodebug(seek_mage_maps)
             )
        ,setup_call_cleanup(S,G,C).


%!      seek_dungeon_maps(+Ids,+K,-Solved,-Mean,+Debug) is det.
%
%       Solve a list of Dungeon maps each K times.
%
%       IDs is a list of ids specifying the dungeon maps to be solved.
%
%       K is an integer, the number of times each map is to be solved.
%
%       Solved is an integer, the number of solved maps.
%
%       Mean is a float, the average number of steps of an FSC solving a
%       map.
%
%       Debug is a boolean denoting whether to debug the solved map,
%       including any SLAMming maps, or not.
%
%       Shameless copy/pasta of solve_dungeon_maps/5 but calling
%       seek_map_target/4 to solve a map with an FSC rather than a
%       solver.
%
seek_dungeon_maps(Is,K,RS,M,Deb):-
        findall(R-N
               ,(member(I,Is)
                ,between(1,K,J)
                ,atom_concat(dungeon_,I,Id)
                ,debug(seek_dungeon_maps,'Solving Dungeon ~w instance ~w',[Id,J])
                ,GL = seek_map_target(dungeon(Id),R,N,Deb)
                % Just in case - since BK executors tend to get stuck here.
                ,CL = call_with_time_limit(300,GL)
                ,catch(CL,time_limit_exceeded,(R = 0
                                              ,N = 0
                                              ,debug(seek_dungeon_maps,
                                                     'Time limit exceeded!',[])
                                              )
                      )
                )
               ,RNs)
        ,pairs_keys_values(RNs,Rs,Ns)
        ,maplist(sumlist,[Rs,Ns],[RS,NS])
        ,length(Ns,L)
        ,M is NS / L.



%!      seek_hard_coded_mage_maps(+Ids,-Solved,-Mean,+Debug) is det.
%
%       Solve a list of hard-coded MaGe maps.
%
%       Ids is a list of ids specifying the maps to be solved.
%
%       Solved is an integer, the number of maps solved.
%
%       Mean is a float, the average number of steps by an FSC to solve
%       a map.
%
%       Debug is a boolean denoting whether to debug the solved map, and
%       any slamming maps, or not.
%
%       Shameless copy/pasta of trace_hard_coded_mage_maps/4, but
%       routing FSCs to executors, obviously.
%
seek_hard_coded_mage_maps(Is,RS,M,Deb):-
        findall(R-N
               ,(member(I,Is)
                ,atom_concat(mage_,I,Id)
                ,debug(seek_mage_maps,'Solving map ~w',[Id])
                ,seek_map_target(id(Id),R,N,Deb)
                )
               ,RNs)
        ,pairs_keys_values(RNs,Rs,Ns)
        ,maplist(sumlist,[Rs,Ns],[RS,NS])
        ,length(Ns,L)
        ,M is NS / L.


%!      seek_map_target(+Type,-Solved,-Steps,+Deb) is det.
%
%       Seek a target on a map with an FSC.
%
%       Type specifies the map to be searched.
%
%       Solved is 1 if the target was found, 0 if not.
%
%       Steps is the number of steps the FSC took on the map to find the
%       target.
%
%       Deb is a boolean denoting whether to print out the solved map,
%       and any slamming map, or not.
%
seek_map_target(Type,R,N,Deb):-
        init_environment(Type,print,_Ds,Fs-s,Q0,O0,Gs-e)
        ,(executor(Fs,Q0,O0,Gs,As,Ms)
         ->  R = 1
            ,length(As,N)
         ;   R = 0
            ,N = 0
         )
        ,(   Deb = true
         ->  debug_fsc_search(Fs,Ms,As,tiles)
         ;   true
         )
         .

%!      debug_fsc_search(+Fluents,+SLAM,+Actions,+What) is det.
%
%       Debug an FSC's solution of a map.
%
%       Debug helper for seek_map_target/4.
%
debug_fsc_search(Fs,Ms,As,W):-
        executors:debug_environment(_,'\nProgress:',print,As,Fs)
        ,(   Ms = [_XY,M]
         ->  nl
            ,writeln('Slamming map:')
            ,print_map(W,M)
         ;   Ms = []
         ->  true
         )
        ,print_up_to(10,As).



%!      solve_all_dungeon_maps(+K,-Results,-Mean,+Debug) is det.
%
%       Solve all known dungeon maps, each K times.
%
%       As solve_dungeon_maps, but solves all 10 dungeon maps generated
%       by the R dungeon generator etc.
%
solve_all_dungeon_maps(K,Rs,M,Deb):-
        dungeon_maps(N)
        ,findall(I
               ,between(1,N,I)
               ,Is)
        ,solve_dungeon_maps(Is,K,Rs,M,Deb).


%!      solve_dungeon_maps(+Dungeons,+K,-Results,-Mean,+Debug) is det.
%
%       Solve a set of Dungeons maps, each K times.
%
%       Dungeons is a list of integers denoting the dungeons to be
%       solved. Each integer I in Dungeons is mapped to a dungeon
%       identifier 'dungeon_I'. Dungeons should be already generated
%       with the R dungeon generator etc.
%
%       K is the number of times that each dungeon specified in Dungeons
%       is to be solved. For each of K times, a new pair of start and
%       goal positions are placed in each I'th dungon map at random, and
%       then a plan is generated to join them.
%
%       Result is an integer, the number of successfully solved dungeon
%       maps, including repetitions. The maximum of Results should be
%       |Dungeons| * K.
%
%       Mean is a float, the mean of the number of actions in plans
%       solving all Dungeons.
%
%       Debug is a boolean denoting whether to print out each solved
%       dungeon map.
%
solve_dungeon_maps(Is,K,RS,M,Deb):-
        findall(R-N
               ,(member(I,Is)
                ,between(1,K,J)
                ,atom_concat(dungeon_,I,Id)
                ,debug(solve_dungeon_maps,'Solving Dungeon ~w instance ~w',[Id,J])
                ,map_solver(dungeon(Id),D-D,R,N,Deb)
                %,trace_map_solver_prims(dungeon(Id),_,R,N,Deb)
                )
               ,RNs)
        ,pairs_keys_values(RNs,Rs,Ns)
        ,maplist(sumlist,[Rs,Ns],[RS,NS])
        ,length(Ns,L)
        ,M is NS / L.


%!      map_solver(+Type,?Dims,-Solved,-Steps,+Debug) is det.
%
%       Try solving a map and report whether it was Solved.
%
%       Type is a map type, one of id/1, mage/1 or dungeon/1, denoting
%       the kind of map to solve.
%
%       Dims is a pair W-H, denoting the dimensions of the map specified
%       in Type. Dims is only used if Type is a mage/1 term, in which
%       case it directs MaGe to generate a map of the given dimensions.
%
%       Solved is a number in [0,1], acting as a Boolean, denoting
%       whether the map specified in Type was solved (1) or not (0).
%
%       Steps is an integer, the number of actions in the plan solving
%       the map specified in Type.
%
%       Debug is a boolean denoting whether to debug the solved map,
%       with debug_environment/5, or not.
%
%       This predicate uses solve_environment/5 and the s/2 solver to
%       solve the specified map. The primitives for the map don't need
%       to be loaded in memory and will be automatically generated
%       during the solution of the map by solve_environment/5.
%
map_solver(Map,Ds,R,S,Deb):-
        /*(   Map = id(Id)
         ->  map_term(Id,Ds,_,M)
         ;   Map = mage(Id)
         ->  mage(Ds,Mz)
            ,map_term(Id,Ds,Mz,M)
         ;   Map = dungeon(Id)
         ->  map_term(Id,Ds,Mz,M)
            ,maze_generator:write_start_exit(random_nondet,Ds,Mz)
         )*/
        id_map(Map,M,Ds,Deb)
        ,Ds = W-H
        ,N is W * H
        ,solver(s/2,Ss)
        ,(   solve_environment(Ss,M,0,N,As_s)
         ->  R = 1
            ,length(As_s,S)
         ;   R = 0
            ,S = nil
         )
        ,(   Deb == true
            ,R == 1
         -> environment_init(M,print,Ds,Fs-s,_Q0,_O0,_Gs-e)
            ,executors:debug_environment(solve,'\nSolver:',print,As_s,Fs)
         ;   true
         )
        ,!.



%!      id_map(+Type,-Map,-Dims,+Debug) is det.
%
%       Return a Map given an identifier of some Type.
%
%       Type is a term of the fomr id/1, mage/1, or dungeon/1, denoting
%       the kind of map to return. Depending on the Type, the map may be
%       loaded in memory (id/1), generated by MaGe (mage/1) or, er,
%       loaded in memory but for dungeon maps only (dungeon/1). OK, so
%       we don't need a separate one for dungeon maps.
%
%       Map is a map/3 term of the retrieved or generated map.
%
%       Dims is the pair W-H of dimensions of Map.
%
%       Debug is a boolean denoting whether to print out the map or not,
%       during execution of this predicate.
%
id_map(Type,Map,Ds,Deb):-
        (   Type = id(Id)
         ->  map_term(Id,Ds,_,Map)
         ;   Type = mage(Id)
         ->  mage(Ds,Mz)
            ,map_term(Id,Ds,Mz,Map)
         ;   Type = dungeon(Id)
         ->  map_term(Id,Ds,Mz,Map)
            ,maze_generator:write_start_exit(random_nondet,Ds,Mz)
         )
        ,(   Deb == true
         ->  print_map(tiles,Map)
         ;   true
         ).


%!      set_memory_limits(+Stack,+Table) is det.
%
%       Set RAM limits for stack and tables.
%
set_memory_limits(SL,TL):-
        set_prolog_flag(stack_limit, SL)
        %,set_prolog_flag(table_space, 51_539_607_552)
        ,set_prolog_flag(table_space, TL)
        ,current_prolog_flag(stack_limit, S)
        ,format('Global stack limit ~D~n',[S])
        ,current_prolog_flag(table_space, T)
        ,format('Table space ~D~n',[T]).


%!      write_mage_maps(+K,+Dimensions) is det.
%
%       Write K MaGe map files of the given Dimensions to files.
%
%       Map files are written to grid_master_data(mazes/Fn) where each
%       Fn is a name mage_<Id>.map, and mage_<Id> is the identifier of
%       the maze map written in the file, created by concatenating mage_
%       and I for the i'th generated maze.
%
write_mage_maps(K,Ds):-
        grid_master_configuration:theme(Th)
        ,S = ( retract(grid_master_configuration:theme(Th))
              ,assert(grid_master_configuration:theme(text))
             )
        ,G = forall(between(1,K,I)
              ,(mage(Ds,Map)
               ,atom_concat(mage_,I,Id)
               ,atom_concat(Id,'.map',Fn)
               ,F = grid_master_data(mazes/Fn)
               ,write_map_file(F,map(Id,Ds,Map))
               ,debug(write_mage_maps,'Wrote map ~w',[Fn])
               )
              )
        ,C = ( retract(grid_master_configuration:theme(text))
              ,assert(grid_master_configuration:theme(Th))
             )
        ,setup_call_cleanup(S,G,C).
