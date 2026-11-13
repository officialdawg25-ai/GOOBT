import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.0";
const cors={ "Access-Control-Allow-Origin":"*", "Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods":"POST, OPTIONS" };
Deno.serve(async (req:Request)=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 if(req.method!=="POST") return new Response(JSON.stringify({error:"method_not_allowed"}),{status:405,headers:{...cors,"Content-Type":"application/json"}});
 const url=Deno.env.get("SUPABASE_URL"), key=Deno.env.get("SUPABASE_ANON_KEY"), auth=req.headers.get("Authorization");
 if(!url||!key||!auth) return new Response(JSON.stringify({error:"configuration_or_auth_missing"}),{status:401,headers:{...cors,"Content-Type":"application/json"}});
 const client=createClient(url,key,{global:{headers:{Authorization:auth}}});
 const {data:{user},error}=await client.auth.getUser();
 if(error||!user) return new Response(JSON.stringify({error:"unauthorized"}),{status:401,headers:{...cors,"Content-Type":"application/json"}});
 // CozyWash stays a distinct authority. No endpoint URL, secret or contract has been supplied.
 return new Response(JSON.stringify({error:"cozywash_adapter_not_configured",message:"Service handoff is blocked until an approved versioned API contract and credentials are provisioned."}),{status:503,headers:{...cors,"Content-Type":"application/json"}});
});