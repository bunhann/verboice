-module(session_test).
-include_lib("eunit/include/eunit.hrl").
-include("session.hrl").
-include("db.hrl").

-record(state, {session_id, session, resume_ptr, pbx_pid, flow_pid, hibernated}).

notify_status_on_completed_ok_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=completed&From=123&CallDuration=0", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_on_failed_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:expect(call_log_srv, hangup_status, 1, {fail, "30", "Random error"}),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=failed&From=123&CallDuration=0&CallStatusReason=Random%20error&CallStatusCode=30", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, {failed, "Random error"}}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_on_failed_with_code_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=failed&From=123&CallDuration=0&CallStatusReason=Random%20error&CallStatusCode=42", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, {failed, {error, "Random error", 42}}}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_on_completed_sends_call_duration_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>, started_at = {{2014,12,11},{16,0,0}}},
  meck:new(calendar, [unstick, passthrough]),
  meck:expect(calendar, universal_time, fun() -> {{2014,12,11},{16,0,5}} end),

  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=completed&From=123&CallDuration=5", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_on_completed_ok_with_callback_params_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>, callback_params = [{"foo", "1"}]},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=completed&From=123&CallDuration=0&foo=1", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_with_http_credentials_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>, status_callback_user = "user", status_callback_password = "pass"},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=completed&From=123&CallDuration=0", [{"Authorization", "Basic dXNlcjpwYXNz"}]}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_on_completed_with_session_vars_test() ->
  Session0 = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com">>, status_callback_include_vars = true, js_context = erjs_context:new()},
  {next, Session1} = js:run([{source, "var_foo = 1"}], Session0),
  {next, Session2} = js:run([{source, "var_bar = 2"}], Session1),
  Session = Session2,

  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),

  meck:new(httpc),
  RequestParams = [get, {"http://foo.com/?CallSid=1&CallStatus=completed&From=123&CallDuration=0&bar=2&foo=1", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),

  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().

notify_status_merges_query_string_test() ->
  Session = #session{address = <<"123">>, call_log = {call_log_srv}, status_callback_url = <<"http://foo.com?sample=1">>},
  meck:new(call_log_srv, [stub_all]),
  meck:expect(call_log_srv, id, 1, 1),
  meck:new(httpc),

  RequestParams = [get, {"http://foo.com/?sample=1&CallSid=1&CallStatus=completed&From=123&CallDuration=0", []}, '_', [{full_result, false}]],
  meck:expect(httpc, request, RequestParams, ok),
  session:in_progress({completed, Session, ok}, #state{session = Session}),

  meck:wait(httpc, request, RequestParams, 1000),
  meck:unload().
