:-  ensure_loaded(lib/controller_freak/controller_freak)
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

:- Prims = grid_master_data('primitives_stack_less.pl')
  ,use_module(lib/grid_master/grid_master_configuration)
  ,retract(grid_master_configuration:action_representation(_))
  ,retract(grid_master_configuration:primitives_file(_,_))
  ,assert(grid_master_configuration:action_representation(stack_less))
  ,assert(grid_master_configuration:primitives_file(Prims,primitives))
  ,writeln('Loading large primitives file. Be patient.')
  ,ensure_loaded(Prims).


%!      mage_maps(?Maps) is semidet.
%
%       Number of MaGe maps to solve.
%
%mage_maps(100).
mage_maps(10).


%!      debug_experiment(?Experiment,?Debug) is det.
%
%       Whether to visualise an Experiment while running, or not.
%
debug_experiment('1a',false):- !.
debug_experiment(_,false).


%!      memory_limites(?Experiment,?Stack,?Table) is det.
%
%       Stack and Table RAM limits for an Experiment.
%
memory_limits('1a',2_147_483_648,17_179_869_184).


:- nodebug(_).
%:- debug(trace_map_solver).
%:- debug(test_instance).
%:- debug(trace_mage_maps).
%:- debug(trace_path).
%:- debug(write_mage_maps).
%:- debug(test_instance).
%:- debug(solve).


%!      experiment_1a is det.
%
%       Solve 100 MaGe maps with a solver.
%
experiment_1a:-
        mage_maps(K)
        ,debug_experiment('1a',Deb)
        ,writeln('Starting experiment_1a')
        ,abolish_all_tables
        ,protocol('experiment_1a.log')
        ,set_memory_limits(2_147_483_648,17_179_869_184)
        ,debug(trace_mage_maps)
        ,debug(trace_map_solver)
        ,findall(I
                ,between(1,K,I)
                ,Is)
        ,trace_hard_coded_mage_maps(Is,Rs,M,Deb)
        ,format('Solved ~w MaGe maps. Mean number of steps: ~2f',[Rs,M])
        ,nodebug(trace_mage_maps)
        ,nodebug(trace_map_solver)
        ,noprotocol.



%!      trace_hard_coded_mage_maps(+Ids,-Solved,-Actions,+Debug) is
%!      det.
%
%       Trace hard-coded MaGe maps with primitives loaded in memory.
%
%       Ids is a list of MaGe map ids. Primitives for each of those maps
%       should already be loaded in memory.
%
%       Solved is an integer denoting the number of solved maps.
%
%       Actions is a float denoting the mean number of step actions in
%       all plans returned by a solver for the solved maps.
%
%       Debug is a boolean denoting whether maps should be printed out.
%
trace_hard_coded_mage_maps(Is,RS,M,Deb):-
        findall(R-N
               ,(member(I,Is)
                ,atom_concat(mage_,I,Id)
                ,debug(trace_mage_maps,'Solving map ~w',[Id])
                ,trace_map_solver_prims(id(Id),_,R,N,Deb)
                )
               ,RNs)
        ,pairs_keys_values(RNs,Rs,Ns)
        ,maplist(sumlist,[Rs,Ns],[RS,NS])
        ,length(Ns,L)
        ,M is NS / L.


%!      trace_map_solver_prims(+Id,+Dims,-Solved,-Steps,+Debug) is
%!      det.
%
%       Solve a hard-coded MaGe map with primitives loaded in memory.
%
%       Id is a term id(Id) identifying the map to be solved. The
%       primitive action predicates for this map should be already
%       loaded in memory. They will not be automatically generated
%       before solving the map.
%
%       Dims are the W-H dimensions of the map to be solved.
%
%       Solved is 1, if the map was solved, 0 if it wasn't.
%
%       Steps is the number of steps in a plan solving the map, 0 if the
%       map wasn't solved.
%
%       Debug is a boolean denoting whether the map should be printed
%       out or not.
%
trace_map_solver_prims(Type,Ds,R,K,Deb):-
        abolish_all_tables
        ,id_map(Type,Map,Ds,Deb)
        ,Ds = W-H
        ,N is W * H
        ,map_term(Id,Ds,_,Map)
        ,solver(s/2,Ss)
        ,S = (assert_program(experiment_file,Ss,Rs_S)
             ,table(experiment_file:s/2 as variant)
             )
        ,G = (experiment_file:test_initialisation(Id,Q0,Q1,[XYs,XYe,Ts,Te,_,_])
             %,start_end_distance(XYs,XYe,Min)
             ,experiment_file:solver_test_instance(s/2,E,[Id,0,N,XYs,XYe,Ts,Te,Q0,Q1])
             ,call_time(experiment_file:E,T,Res)
             ,Res \== false
             ,!
             ,(   solve_map(E,K)
              ->  R = 1
                 ,debug_solved_instance(E,T,K)
              ;   R = 0
                 ,K = 0
              )
             )
        ,C = (erase_program_clauses(Rs_S)
             ,untable(experiment_file:s/2)
             )
        ,setup_call_cleanup(S,G,C).


%!      start_end_distance(+Start,+End,-Distance) is det.
%
%       Calculate the Manhattan distance betwen Start and End locations.
%
%       @tbd Not used.
%
start_end_distance(Xs/Ys,Xe/Ye,D):-
        D1 is abs(Xs - Xe)
        ,D2 is abs(Ys - Ye)
        ,D is abs(D1 + D2).


%!      debug_solved_instance(+Example,+Time) is det.
%
%       Debug a solved instance of a plannng problem.
%
%       Example is an instance of s/2.
%
%       Time is a dict returned by call_time/3, with timing information
%       for the execution of Example.
%
debug_solved_instance(E,T,K):-
        format(atom(M),'Solved instance with ~w actions in ~4f sec: ',[K,T.wall])
        ,debug_clauses(trace_map_solver,M,E).



%!      solve_map(+Example,-Count) is nondet.
%
%       Solve an Example map and Count the number of steps taken.
%
%       Similar to trace_path_/4 but directly calls the meta-interpreter
%       execute_plan/5 to generate a path through a map and count the
%       steps needed to find it, without printing out the result.
%
solve_map(E,C_):-
        C = c(0)
        ,definition_module(E,M)
        ,debug(trace_path,'Finding a path...',[])
        ,time( execute_plan(M,C,E,[],Cs) )
        ,length(Cs,C_)
        % execute_plan/5 may backtrack unnecessarily.
        ,!.
solve_map(_E,0):-
        debug(trace_path,'Failed to find a path!~n~n',[]).



%!      definition_module(+Instance,-Module) is det.
%
%       Definition Module of a testing Instance.
%
%       Instance is a testing instance for a learned predicate, as
%       returned by testing_instance/3, defined in the current
%       experiment file.
%
%       Module is the definition module of the program defining the
%       predicate of the testing instance. This is used to locate the
%       definition of the predicate so that it ca be tested.
%
%       The experiment file setup seems to change the module where
%       testing_instance/3 is defined everytime the experiment file is
%       loaded.
%
definition_module(E,experiment_file):-
        functor(E,F,A)
        ,current_predicate(experiment_file:F/A)
        ,!.
definition_module(E,M):-
        configuration:experiment_file(_P,M)
        ,functor(E,F,A)
        ,current_predicate(M:F/A).



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
