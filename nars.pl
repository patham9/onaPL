% nars.pl
% GNU Lesser General Public License
% Author: Patrick Hammer

:- [nal].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%memory.pl

%11.1.2 State accumulation using engines - https://www.swi-prolog.org/pldoc/man?section=engine-state
:- use_module(library(heaps)).

create_heap(E) :- empty_heap(H), engine_create(_, update_heap(H), E).
update_heap(H) :- engine_fetch(Command), ( update_heap(Command, Reply, H, H1) ->  true; H1 = H, Reply = false ), engine_yield(Reply), update_heap(H1).

update_heap(add(Priority, Key), true, H0, H) :- add_to_heap(H0, Priority, Key, H).
update_heap(get(Priority, Key), Priority-Key, H0, H) :- get_from_heap(H0, Priority, Key, H).

heap_add(Priority, Key, E) :- engine_post(E, add(Priority, Key), true).

heap_get(Priority, Key, E) :- engine_post(E, get(Priority, Key), Priority-Key).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%control.pl

priority([_, [F,C]], P) :- f_exp([F, C], E), P is 1.0-E.

input_event(Event) :- heap_add(0.0, Event, belief_events_queue).

derive_event(Event, P) :- priority(Event, P), heap_add(P, Event, belief_events_queue).

inference_step(_) :- heap_get(Priority1, Premise1, belief_events_queue),
                     heap_get(Priority2, Premise2, belief_events_queue),
                     heap_add(Priority2, Premise2, belief_events_queue), %undo removal of the second premise (TODO)
                     write("Selected premises: Premise1="), write(Premise1), write(" Premise2="), write(Premise2), nl,
                     findall(Conclusion, ((inference(Premise1, Conclusion) ; inference(Premise1, Premise2, Conclusion) ; inference(Premise2, Premise1, Conclusion)), derive_event(Conclusion, P), write(Conclusion), write(". Priority="), write(P), nl), _)
                     ; true.

main :- create_heap(belief_events_queue), main(1).
main(T) :- read(X), (X = 1 -> write("performing 1 inference steps:"), nl, inference_step(T), write("done with 1 additional inference steps."), nl, main(T+1) 
                            ; write("Input: "), write(X), nl, input_event(X), main(T+1)).

