import 'package:supabase/supabase.dart';

import 'config.dart';
import 'demo_repository.dart';
import 'repository.dart';
import 'supabase_repository.dart';

/// Picks the backend from configuration (demo by default).
FbRepository createRepository(FbConfig config) => config.isDemo
    ? DemoRepository()
    : SupabaseRepository(SupabaseClient(config.supabaseUrl, config.supabaseAnonKey));
