import "jsr:@supabase/functions-js/edge-runtime.d.ts";
Deno.serve(async (req:Request)=>{
 if(req.method!=="POST") return new Response(JSON.stringify({error:"method_not_allowed"}),{status:405,headers:{"Content-Type":"application/json"}});
 // No payment provider has been selected. Do not accept arbitrary webhook state changes.
 return new Response(JSON.stringify({error:"webhook_provider_not_configured"}),{status:503,headers:{"Content-Type":"application/json"}});
});